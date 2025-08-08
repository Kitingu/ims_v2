defmodule Ims.Workers.UploadStaffMembersWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  alias Ims.Accounts.{User, JobGroup}
  alias Ims.Repo

  import Ecto.Changeset
  import Ecto.Query
  require Logger

  @required_headers [
    "Payroll Number",
    "Full Name",
    "ID Number",
    "Gender",
    "Age",
    "Designation",
    "Job Group",
    "sys_user",
    "department id"
  ]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"admin_id" => admin_id, "path" => path}}) do
    if not File.exists?(path) do
      Logger.warning("❌ Skipping retry — file no longer exists: #{path}")
      :discard
    else
      Logger.info("📥 Processing Excel file: #{path} (admin_id: #{admin_id})")

      case process_excel_file(path, admin_id) do
        {:ok, _} ->
          File.rm(path)
          :ok

        {:error, reason} ->
          Logger.error("❌ Upload failed: #{inspect(reason)}")
          File.rm(path)
          {:error, reason}
      end
    end
  end

  defp process_excel_file(path, admin_id) do
    with {:ok, rows} <- read_excel_file(path),
         {:ok, _} <- create_users_from_rows(rows, admin_id) do
      {:ok, "Users uploaded successfully"}
    else
      error -> error
    end
  end

  defp read_excel_file(path) do
    case Xlsxir.multi_extract(path, 0) do
      {:ok, table_id} ->
        rows = Xlsxir.get_list(table_id)
        Xlsxir.close(table_id)

        case rows do
          [header | data] when length(data) > 0 ->
            headers_trimmed = Enum.map(header, &String.trim/1)

            if headers_trimmed == @required_headers do
              {:ok, data}
            else
              {:error,
               "Invalid Excel headers. Required headers: #{@required_headers |> Enum.join(", ")}, got: #{inspect(header)}"}
            end

          [_] -> {:error, "Excel file contains only headers"}
          [] -> {:error, "Excel sheet is empty"}
        end

      {:error, reason} -> {:error, "Failed to parse Excel: #{inspect(reason)}"}
    end
  end

  defp create_users_from_rows(rows, admin_id) do
    Enum.with_index(rows, 1)
    |> Enum.each(fn {row, index} ->
      Logger.debug("🚧 [Row #{index}] Processing: #{inspect(row)}")

      case safe_parse_row_to_attrs(row, admin_id) do
        {:ok, attrs} ->
          if personal_number_exists?(attrs.personal_number) do
            Logger.warning("⚠️ [Row #{index}] Duplicate personal_number: #{attrs.personal_number}")
          else
            case create_user(attrs) do
              {:ok, user} ->
                Logger.info("✅ [Row #{index}] Inserted user: #{user.first_name} #{user.last_name}")

              {:error, %Ecto.Changeset{} = changeset} ->
                Logger.error("❌ [Row #{index}] Insert failed: #{inspect(changeset.errors)}")

              {:error, reason} ->
                Logger.error("❌ [Row #{index}] Unexpected error: #{inspect(reason)}")
            end
          end

        {:error, reason} ->
          Logger.error("❌ [Row #{index}] Skipped — #{reason}: #{inspect(row)}")
      end
    end)

    Phoenix.PubSub.broadcast(
      Ims.PubSub,
      "users:upload",
      {:users_uploaded, admin_id, "User upload completed successfully."}
    )

    {:ok, :done}
  end

  defp safe_parse_row_to_attrs(row, admin_id) do
    try do
      parse_row_to_attrs(row, admin_id)
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp parse_row_to_attrs(row, admin_id) do
    Logger.debug("🚧 Raw row: #{inspect(row)}")

    case row do
      [
        personal_number,
        full_name,
        id_number,
        gender,
        _age,
        designation,
        job_group_name,
        sys_user_raw
      ] ->
        parse_row_to_attrs(row ++ [1], admin_id)

      [
        personal_number,
        full_name,
        id_number,
        gender,
        _age,
        designation,
        job_group_name,
        sys_user_raw,
        department_id_raw
      ] ->
        {first_name, last_name} = parse_full_name(full_name)
        gender = parse_gender(gender)

        sys_user =
          case to_string(sys_user_raw) |> String.downcase() do
            "true" -> true
            "yes" -> true
            _ -> false
          end

        email = if sys_user, do: "#{personal_number}@example.com", else: nil
        password = if sys_user, do: generate_temp_password(), else: nil

        job_group = get_or_create_job_group(job_group_name, admin_id)
        department_id = parse_department_id(department_id_raw)

        {:ok,
         %{
           email: email,
           password: password,
           password_confirmation: password,
           first_name: first_name,
           last_name: last_name,
           id_number: to_string(id_number),
           personal_number: to_string(personal_number),
           designation: to_string(designation),
           gender: gender,
           job_group_id: job_group.id,
           department_id: department_id,
           sys_user: sys_user,
           password_reset_required: sys_user
         }}

      _ ->
        {:error, "Invalid row format or missing columns"}
    end
  end

  defp create_user(attrs) do
    Repo.transaction(fn ->
      changeset =
        if attrs.sys_user do
          %User{}
          |> User.registration_changeset(attrs)
          |> put_change(:confirmed_at, DateTime.utc_now() |> DateTime.truncate(:second))
        else
          %User{}
          |> User.staff_member_changeset(attrs)
        end

      case Repo.insert(changeset) do
        {:ok, user} ->
          if user.sys_user do
            {:ok, _} =
              Ims.Accounts.deliver_user_confirmation_instructions(
                user,
                fn token -> ImsWeb.Endpoint.url() <> "/users/confirm/#{token}" end
              )
          end

          {:ok, user}

        error ->
          Repo.rollback(error)
      end
    end)
  end

  defp get_or_create_job_group(name, admin_id) do
    Repo.get_by(JobGroup, name: name) ||
      %JobGroup{}
      |> JobGroup.changeset(%{
        name: name,
        description: "Auto-created during user upload",
        created_by_id: admin_id
      })
      |> Repo.insert!()
  end

  defp parse_full_name(nil), do: {"Unknown", "Unknown"}

  defp parse_full_name(full_name) do
    full_name
    |> String.replace(~r/\\b(Mr|Mrs|Ms|Miss|Dr|Prof|Hon|Mr\\.)\\.?/i, "")
    |> String.trim()
    |> String.split()
    |> case do
      [first] -> {first, "Unknown"}
      [first | rest] -> {first, Enum.join(rest, " ")}
      _ -> {"Unknown", "Unknown"}
    end
  end

  defp parse_gender("F"), do: "Female"
  defp parse_gender("M"), do: "Male"
  defp parse_gender(g), do: String.capitalize(to_string(g || "Other"))

  defp email_exists?(nil), do: false
  defp email_exists?(email), do: Repo.exists?(from u in User, where: u.email == ^email)

  defp personal_number_exists?(nil), do: false
  defp personal_number_exists?(pn), do: Repo.exists?(from u in User, where: u.personal_number == ^pn)

  defp generate_temp_password do
    upper = Enum.random(?A..?Z) |> to_string()
    lower = Enum.random(?a..?z) |> to_string()
    digit = Enum.random(?0..?9) |> to_string()
    punct = Enum.random(~c"!@#$%^&*") |> to_string()
    rest = :crypto.strong_rand_bytes(6) |> Base.encode64() |> binary_part(0, 6)
    upper <> lower <> digit <> punct <> rest
  end

  defp parse_department_id(nil), do: 1
  defp parse_department_id(value) when is_integer(value), do: value
  defp parse_department_id(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {int, _} -> int
      _ -> 1
    end
  end
  defp parse_department_id(_), do: 1
end

defmodule Ims.Workers.UploadUsersWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  alias Ims.Accounts
  alias Ims.Accounts.User
  alias Ims.Repo
  import Ecto.Changeset
  import Ecto.Query
  require Logger

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
          [_header | data] when length(data) > 0 -> {:ok, data}
          [_] -> {:error, "Excel file contains only headers"}
          [] -> {:error, "Excel sheet is empty"}
        end

      {:error, reason} ->
        {:error, "Failed to parse Excel: #{inspect(reason)}"}
    end
  end

  defp create_users_from_rows(rows, admin_id) do
    Enum.each(rows, fn row ->
      with {:ok, attrs} <- parse_row_to_attrs(row),
           false <- email_exists?(attrs.email),
           {:ok, _user} <- create_user(attrs, admin_id) do
        Logger.info("✅ Inserted user: #{attrs.email}")
      else
        true ->
          Logger.warning("⚠️ Skipping duplicate email: #{Enum.at(row, 0)}")

        {:error, changeset} ->
          Logger.error("❌ Insert failed: #{inspect(changeset.errors)}")

        {:error, reason} ->
          Logger.error("❌ Row error: #{reason}")
      end
    end)

    Phoenix.PubSub.broadcast(
      Ims.PubSub,
      "users:upload",
      {:users_uploaded, admin_id, "User upload completed successfully."}
    )

    {:ok, :done}
  end

  defp parse_row_to_attrs([
         email,
         first_name,
         last_name,
         msisdn,
         personal_number,
         designation,
         gender,
         department_id,
         job_group_id
       ]) do
    password = generate_temp_password()

    {:ok,
     %{
       email: to_string(email),
       first_name: to_string(first_name),
       last_name: to_string(last_name),
       msisdn: to_string(msisdn),
       personal_number: to_string(personal_number),
       designation: to_string(designation),
       gender: to_string(gender),
       department_id: parse_id(department_id),
       job_group_id: parse_id(job_group_id),
       password: password,
       password_confirmation: password,
       password_reset_required: true
     }}
  rescue
    _ -> {:error, "Invalid row format or missing columns"}
  end

  defp parse_id(nil), do: nil
  defp parse_id(value) when is_integer(value), do: value
  defp parse_id(value) when is_binary(value), do: String.to_integer(value)
  defp parse_id(_), do: nil

  defp generate_temp_password do
    upper = Enum.random(?A..?Z) |> to_string()
    lower = Enum.random(?a..?z) |> to_string()
    digit = Enum.random(?0..?9) |> to_string()
    punct = Enum.random(~c"!@#$%^&*") |> to_string()
    rest = :crypto.strong_rand_bytes(6) |> Base.encode64() |> binary_part(0, 6)
    upper <> lower <> digit <> punct <> rest
  end

  defp create_user(attrs, _admin_id) do
    %User{}
    |> User.registration_changeset(attrs)
    |> put_change(:confirmed_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> Repo.insert()
  end

  defp email_exists?(email) do
    Repo.exists?(from u in User, where: u.email == ^email)
  end
end

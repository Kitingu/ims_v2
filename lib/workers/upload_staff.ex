defmodule Ims.Workers.UploadStaffMembersWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  alias Ims.Accounts.{User, JobGroup}
  alias Ims.Repo

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
        {:ok, _summary} ->
          File.rm(path)
          :ok

        {:error, reason} ->
          Logger.error("❌ Upload failed: #{inspect(reason)}")
          File.rm(path)
          {:error, reason}
      end
    end
  end

  # ============================================================
  # Pipeline
  # ============================================================

  defp process_excel_file(path, admin_id) do
    with {:ok, rows} <- read_excel_file(path),
         {:ok, summary} <- create_users_from_rows(rows, admin_id) do
      {:ok, summary}
    else
      error -> error
    end
  end

  # ============================================================
  # Excel reading
  # ============================================================

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
               "Invalid Excel headers. Required: #{Enum.join(@required_headers, ", ")}, got: #{inspect(header)}"}
            end

          [_] -> {:error, "Excel file contains only headers"}
          [] -> {:error, "Excel sheet is empty"}
        end

      {:error, reason} ->
        {:error, "Failed to parse Excel: #{inspect(reason)}"}
    end
  end

  # ============================================================
  # Fault-tolerant row processing
  # ============================================================

  defp create_users_from_rows(rows, admin_id) do
    results =
      rows
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        Logger.debug("🚧 [Row #{index}] Processing: #{inspect(row)}")

        try do
          case safe_parse_row_to_attrs(row, admin_id) do
            {:ok, attrs} ->
              # Critical keys present & not blank?
              case ensure_required_attrs(attrs, [:personal_number, :id_number, :designation, :job_group_id]) do
                :ok ->
                  if personal_number_exists?(attrs.personal_number) do
                    Logger.warning("⚠️ [Row #{index}] Duplicate personal_number: #{attrs.personal_number}")
                    {:skipped_duplicate, index, %{personal_number: attrs.personal_number}}
                  else
                    case create_user(attrs) do
                      {:ok, %User{} = user} ->
                        Logger.info("✅ [Row #{index}] Inserted user: #{user.first_name} #{user.last_name}")
                        {:ok, index, %{id: user.id, pn: user.personal_number}}

                      {:error, %Ecto.Changeset{} = changeset} ->
                        Logger.error("❌ [Row #{index}] Insert failed: #{inspect(changeset.errors)}")
                        {:error_changeset, index, %{errors: changeset.errors, attrs: redact(attrs)}}

                      {:error, reason} ->
                        Logger.error("❌ [Row #{index}] Unexpected insert error: #{inspect(reason)}")
                        {:error_other, index, %{reason: inspect(reason), attrs: redact(attrs)}}
                    end
                  end

                {:missing, missing_keys} ->
                  Logger.error("❌ [Row #{index}] Missing required fields: #{Enum.join(missing_keys, ", ")}")
                  {:error_missing_keys, index, %{missing: missing_keys, row: row}}
              end

            {:error, reason} ->
              Logger.error("❌ [Row #{index}] Skipped — #{reason}: #{inspect(row)}")
              {:error_parse, index, %{reason: reason, row: row}}
          end
        rescue
          e ->
            Logger.error("💥 [Row #{index}] Exception (#{inspect(e.__struct__)}):\n" <>
                           Exception.format(:error, e, __STACKTRACE__))

            {:error_exception, index, %{error: Exception.message(e), type: e.__struct__}}
        end
      end)

    summary = summarize_results(results)
    log_summary(summary)

    Phoenix.PubSub.broadcast(
      Ims.PubSub,
      "users:upload",
      {:users_uploaded, admin_id, summary_to_message(summary)}
    )

    {:ok, summary}
  end

  # ============================================================
  # Row → attrs parsing
  # ============================================================

  defp safe_parse_row_to_attrs(row, admin_id) do
    try do
      parse_row_to_attrs(row, admin_id)
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  # Accept 8 or 9 columns; 8 → default department_id 1
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
            "1" -> true
            _ -> false
          end

        email = if sys_user, do: "#{personal_number}@example.com", else: nil
        password = if sys_user, do: generate_temp_password(), else: nil

        job_group_name = job_group_name |> to_string() |> String.trim()
        if job_group_name == "" do
          {:error, "Job Group is blank"}
        else
          job_group = get_or_create_job_group(job_group_name, admin_id)
          department_id = parse_department_id(department_id_raw)

          attrs =
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
            }

          {:ok, attrs}
        end

      _ ->
        {:error, "Invalid row format or missing columns"}
    end
  end

  # ============================================================
  # Name parsing (comma-aware, title stripping, punctuation safe)
  # ============================================================

  defp parse_full_name(nil), do: {"Unknown", "Unknown"}

  defp parse_full_name(full_name) when is_binary(full_name) do
    clean_name =
      full_name
      |> strip_titles()
      |> String.replace(~r/\s+/, " ")
      |> String.trim()
      |> String.trim_leading("., ")
      |> String.trim_trailing("., ")

    if String.contains?(clean_name, ",") do
      [left, right | _] =
        clean_name
        |> String.split(",", parts: 2)
        |> Enum.map(&sanitize_block/1)

      surname_block = left

      right_parts =
        right
        |> String.split(" ", trim: true)
        |> Enum.map(&sanitize_block/1)
        |> Enum.reject(&(&1 == ""))

      case right_parts do
        [first_only] ->
          {proper_case(first_only), proper_case(surname_block)}

        [first | rest] ->
          middle_block = Enum.join(rest, " ") |> sanitize_block()

          last =
            [middle_block, surname_block]
            |> Enum.reject(&(&1 == ""))
            |> Enum.join(" ")
            |> sanitize_block()

          {proper_case(first), proper_case(last)}
      end
    else
      parts =
        clean_name
        |> String.split(" ", trim: true)
        |> Enum.map(&sanitize_block/1)
        |> Enum.reject(&(&1 == ""))

      case parts do
        [first] -> {proper_case(first), "Unknown"}
        [first | rest] -> {proper_case(first), proper_case(Enum.join(rest, " "))}
        _ -> {"Unknown", "Unknown"}
      end
    end
  end

  # Remove one or more honorifics at start; tolerate extra dots/spaces; case-insensitive
  defp strip_titles(str) do
    String.replace(str, ~r/^\s*(?:(?:Mr|Mrs|Ms|Miss|Dr|Prof|Hon)\.*\s+)+/iu, "")
  end

  defp sanitize_block(s) do
    s
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.trim_leading("., ")
    |> String.trim_trailing("., ")
  end

  defp proper_case(str) do
    str
    |> String.downcase()
    |> String.split(~r/\s+/, trim: true)
    |> Enum.map(fn word ->
      case String.length(word) do
        1 -> String.upcase(word)   # keep initials like "Z"
        _ -> String.capitalize(word)
      end
    end)
    |> Enum.join(" ")
  end

  # ============================================================
  # DB ops
  # ============================================================

  # Return shape: {:ok, %User{}} | {:error, reason}
  defp create_user(attrs) do
    Repo.transaction(fn ->
      changeset =
        if attrs.sys_user do
          %User{}
          |> User.registration_changeset(attrs)
          |> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now() |> DateTime.truncate(:second))
        else
          %User{} |> User.staff_member_changeset(attrs)
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

          user  # return the struct from inside the txn

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
    |> case do
      {:ok, %User{} = user} -> {:ok, user}
      {:error, reason} -> {:error, reason}
    end
  end

  # Conflict-tolerant (requires unique index on job_groups.name)
  # create unique_index(:job_groups, [:name])
  defp get_or_create_job_group(name, admin_id) do
    case Repo.get_by(JobGroup, name: name) do
      %JobGroup{} = jg ->
        jg

      nil ->
        params = %{
          name: name,
          description: "Auto-created during user upload",
          created_by_id: admin_id
        }

        changeset = JobGroup.changeset(%JobGroup{}, params)

        case Repo.insert(changeset, on_conflict: :nothing, conflict_target: :name, returning: true) do
          {:ok, %JobGroup{} = jg} -> jg
          {:ok, _} -> Repo.get_by!(JobGroup, name: name)
          {:error, _} -> Repo.get_by!(JobGroup, name: name)
        end
    end
  end

  # ============================================================
  # Validators / existence checks
  # ============================================================

  defp ensure_required_attrs(map, required_keys) when is_map(map) do
    missing =
      required_keys
      |> Enum.reject(&Map.has_key?(map, &1))
      |> Enum.concat(required_blank_keys(map, required_keys))

    case missing do
      [] -> :ok
      _ -> {:missing, Enum.uniq(missing)}
    end
  end

  defp required_blank_keys(map, keys) do
    keys
    |> Enum.filter(fn k ->
      case Map.get(map, k) do
        nil -> true
        "" -> true
        _ -> false
      end
    end)
  end

  defp email_exists?(nil), do: false
  defp email_exists?(email), do: Repo.exists?(from u in User, where: u.email == ^email)

  defp personal_number_exists?(nil), do: false
  defp personal_number_exists?(pn), do: Repo.exists?(from u in User, where: u.personal_number == ^pn)

  # ============================================================
  # Misc parsers
  # ============================================================

  defp parse_gender("F"), do: "Female"
  defp parse_gender("M"), do: "Male"
  defp parse_gender(g), do: String.capitalize(to_string(g || "Other"))

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

  # ============================================================
  # Result summarization / logging
  # ============================================================

  defp summarize_results(results) do
    summary =
      %{
        inserted: for({:ok, idx, info} <- results, do: %{row: idx, info: info}),
        duplicates: for({:skipped_duplicate, idx, info} <- results, do: %{row: idx, info: info}),
        parse_errors: for({:error_parse, idx, info} <- results, do: %{row: idx, info: info}),
        missing_key_errors: for({:error_missing_keys, idx, info} <- results, do: %{row: idx, info: info}),
        changeset_errors: for({:error_changeset, idx, info} <- results, do: %{row: idx, info: info}),
        other_errors: for({:error_other, idx, info} <- results, do: %{row: idx, info: info}),
        exceptions: for({:error_exception, idx, info} <- results, do: %{row: idx, info: info})
      }

    counts =
      %{
        inserted: length(summary.inserted),
        duplicates: length(summary.duplicates),
        parse_errors: length(summary.parse_errors),
        missing_key_errors: length(summary.missing_key_errors),
        changeset_errors: length(summary.changeset_errors),
        other_errors: length(summary.other_errors),
        exceptions: length(summary.exceptions),
        total_rows: length(results)
      }

    Map.put(summary, :counts, counts)
  end

  defp log_summary(summary) do
    c = summary.counts

    Logger.info(
      "📊 Upload summary — Inserted: #{c.inserted}, Duplicates: #{c.duplicates}, " <>
        "Parse: #{c.parse_errors}, Missing: #{c.missing_key_errors}, " <>
        "Changeset: #{c.changeset_errors}, Other: #{c.other_errors}, " <>
        "Exceptions: #{c.exceptions}, Total: #{c.total_rows}"
    )

    Enum.each(summary.inserted, fn %{row: r, info: i} -> Logger.debug("➕ inserted row=#{r} #{inspect(i)}") end)
    Enum.each(summary.duplicates, fn %{row: r, info: i} -> Logger.debug("🔁 duplicate row=#{r} #{inspect(i)}") end)
    Enum.each(summary.parse_errors, fn %{row: r, info: i} -> Logger.debug("🧹 parse error row=#{r} #{inspect(i)}") end)
    Enum.each(summary.missing_key_errors, fn %{row: r, info: i} -> Logger.debug("🚫 missing keys row=#{r} #{inspect(i)}") end)
    Enum.each(summary.changeset_errors, fn %{row: r, info: i} -> Logger.debug("📝 changeset error row=#{r} #{inspect(i)}") end)
    Enum.each(summary.other_errors, fn %{row: r, info: i} -> Logger.debug("❓ other error row=#{r} #{inspect(i)}") end)
    Enum.each(summary.exceptions, fn %{row: r, info: i} -> Logger.debug("💥 exception row=#{r} #{inspect(i)}") end)
  end

  defp summary_to_message(summary) do
    c = summary.counts

    "User upload completed. " <>
      "Inserted: #{c.inserted}, Duplicates: #{c.duplicates}, " <>
      "Parse Errors: #{c.parse_errors}, Missing Keys: #{c.missing_key_errors}, " <>
      "Changeset Errors: #{c.changeset_errors}, Other Errors: #{c.other_errors}, " <>
      "Exceptions: #{c.exceptions}, Total: #{c.total_rows}"
  end

  defp redact(attrs) when is_map(attrs), do: Map.drop(attrs, [:password, :password_confirmation])
end

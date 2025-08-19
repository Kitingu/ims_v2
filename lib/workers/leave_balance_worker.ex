defmodule Ims.Leave.Workers.LeaveBalanceUploadWorker do
  @moduledoc """
  Imports HR-format Excel and updates:
    - User department (if provided)
    - Annual Leave balance from `FY2025/2026 Leave total` only

  Expected headers (case/spacing tolerant):
    - "Personal Number" (required)
    - "Department" (optional)
    - "FY2025/2026 Leave total" (required for updating balance)
  """

  use Oban.Worker, queue: :imports, max_attempts: 3

  alias Ims.Repo.Audited, as: Repo
  import Ecto.Query

  alias Ims.Accounts.{User, Departments}
  alias Ims.Leave.{LeaveType, LeaveBalance}
  require Logger

  @annual_leave_name "Annual Leave"

  # ===== PUBLIC =====

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"xlsx_path" => path}}) when is_binary(path) do
    with {:ok, rows} <- load_xlsx(path) do
      process_rows(rows)
    end
  end

  def perform(%Oban.Job{args: %{"sheet" => rows}}) when is_list(rows), do: process_rows(rows)
  def perform(%Oban.Job{args: _}), do: {:discard, ~s|Provide "xlsx_path" or "sheet"|}

  # ===== IO / LOAD =====

  defp load_xlsx(path) do
    unless File.regular?(path), do: {:error, "Excel file not found at #{path}"}

    case Xlsxir.multi_extract(path, 0) do
      {:ok, tid} ->
        try do
          {:ok, Xlsxir.get_list(tid)}
        after
          Xlsxir.close(tid)
        end

      {:error, reason} ->
        {:error, to_string(reason)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  # ===== DRIVER =====

  defp process_rows([]),
    do: {:ok, %{updated_balances: 0, updated_departments: 0, errors: [[1, %{}, "Empty sheet"]]}}

  defp process_rows([header | data_rows]) do
    with {:ok, ix} <- build_index(header),
         {:ok, annual_lt_id} <- fetch_annual_leave_type_id() do
      Repo.transaction(fn ->
        {bal_count, dept_count, errs} =
          data_rows
          |> Stream.with_index(2) # Excel row numbers start at 2
          |> Enum.reduce({0, 0, []}, fn {row, rno}, {acc_bal, acc_dept, acc_errs} ->
            case process_row(row, ix, annual_lt_id) do
              {:ok, bal_updated?, dept_updated?} ->
                {acc_bal + if(bal_updated?, do: 1, else: 0),
                 acc_dept + if(dept_updated?, do: 1, else: 0),
                 acc_errs}

              {:error, msg} ->
                {acc_bal, acc_dept, [{rno, %{}, msg} | acc_errs]}
            end
          end)

        summary = %{
          updated_balances: bal_count,
          updated_departments: dept_count,
          errors: Enum.reverse(errs)
        }

        Logger.info("Annual leave upload summary: #{inspect(summary)}")
        summary
      end)
      |> case do
        {:ok, summary} -> {:ok, summary}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  # ===== HEADER INDEX =====

  defp build_index(header) when is_list(header) do
    norm_pairs =
      header
      |> Enum.with_index()
      |> Enum.map(fn {h, i} -> {normalize(h), i} end)
      |> Enum.into(%{})

    if Map.has_key?(norm_pairs, "personal number") do
      {:ok, norm_pairs}
    else
      {:error, "Missing required header: Personal Number"}
    end
  end

  # ===== PER-ROW =====

  defp process_row(row, ix, annual_lt_id) do
    raw_pno = fetch(row, ix["personal number"])
    pno = normalize_personal_number(raw_pno)

    if pno == "" do
      {:error, "Missing or invalid Personal Number"}
    else
      {:ok, dept_updated?} = update_user_department_from_row(row, ix, pno)

      case Repo.one(from u in User, where: u.personal_number == ^pno, limit: 1) do
        nil ->
          {:error, "User not found: #{inspect(raw_pno)}"}

        %User{} = user ->
          bal_updated? = update_annual_leave_from_row(user, row, ix, annual_lt_id)
          {:ok, bal_updated?, dept_updated?}
      end
    end
  end

  # ===== DEPARTMENT UPDATE =====

  defp update_user_department_from_row(row, ix, pno) do
    dept_idx = Map.get(ix, "department")

    cond do
      is_nil(dept_idx) ->
        {:ok, false}

      true ->
        dept_name = fetch(row, dept_idx) |> clean()

        if dept_name == "" do
          {:ok, false}
        else
          case Repo.one(from u in User, where: u.personal_number == ^pno, limit: 1) do
            nil -> {:ok, false}
            %User{} = user ->
              dept_id = upsert_department_id(dept_name)

              if user.department_id == dept_id do
                {:ok, false}
              else
                case Repo.update(Ecto.Changeset.change(user, department_id: dept_id)) do
                  {:ok, _} -> {:ok, true}
                  {:error, _} -> {:ok, false}
                end
              end
          end
        end
    end
  end

  defp upsert_department_id(""), do: nil

  defp upsert_department_id(name) do
    norm = String.trim(name)

    case Repo.one(from d in Departments, where: ilike(d.name, ^norm), limit: 1) do
      nil ->
        %Departments{}
        |> Departments.changeset(%{name: norm})
        |> Repo.insert()
        |> case do
          {:ok, d} -> d.id
          {:error, _} -> nil
        end

      %Departments{id: id} ->
        id
    end
  end

  # ===== ANNUAL LEAVE ONLY =====

  defp update_annual_leave_from_row(%User{id: uid}, row, ix, annual_lt_id) do
    total_idx = Map.get(ix, normalize("FY2025/2026 Leave total"))

    case read_decimal(row, total_idx) do
      {:ok, dec} ->
        case LeaveBalance.upsert_leave_balance(%{
               user_id: uid,
               leave_type_id: annual_lt_id,
               remaining_days: dec
             }) do
          {:ok, _} -> true
          {:error, _} -> false
        end

      _ ->
        false
    end
  end

  defp fetch_annual_leave_type_id do
    case Repo.one(from lt in LeaveType, where: ilike(lt.name, ^@annual_leave_name), select: lt.id, limit: 1) do
      nil -> {:error, "Leave type not found: #{@annual_leave_name}"}
      id -> {:ok, id}
    end
  end

  # ===== HELPERS =====

  # Robustly read a decimal from Excel cell (int/float/string), ensure non-negative and 2dp
  defp read_decimal(_row, nil), do: :skip
  defp read_decimal(row, idx) do
    raw = fetch(row, idx)
    if provided?(raw), do: to_nonneg_decimal(raw), else: :skip
  end

  defp fetch(row, nil), do: nil
  defp fetch(row, idx) when is_list(row) do
    case Enum.fetch(row, idx) do
      {:ok, v} -> v
      :error -> nil
    end
  end

  # ---- Personal Number normalization ----
  # Excel often gives personal numbers as floats (e.g. 2009067782.0) or scientific notation (2.40304e7).
  # Convert anything we get into a clean digit-only string without losing leading zeros.
  defp normalize_personal_number(nil), do: ""
  defp normalize_personal_number(v) when is_integer(v), do: Integer.to_string(v)
  defp normalize_personal_number(v) when is_float(v) do
    # compact drops trailing .0 and expands scientific notation
    :erlang.float_to_binary(v, [:compact, decimals: 0])
  end

  defp normalize_personal_number(v) when is_binary(v) do
    s = v |> String.trim() |> String.replace(",", "")

    cond do
      s == "" ->
        ""

      # Already pure digits
      String.match?(s, ~r/^\d+$/) ->
        s

      # Looks like a float or sci-notation; try Decimal first for accuracy, fallback to Float
      String.match?(s, ~r/^[+-]?\d+(\.\d+)?([eE][+-]?\d+)?$/) ->
        case Decimal.parse(s) do
          {:ok, d} ->
            d
            |> Decimal.round(0) # nearest integer
            |> Decimal.to_string(:normal)
            |> String.replace(~r/\.0+$/, "")

          :error ->
            case Float.parse(s) do
              {f, _} -> :erlang.float_to_binary(f, [:compact, decimals: 0])
              :error -> String.replace(s, ~r/\D/, "")
            end
        end

      true ->
        # Last resort: strip all non-digits
        String.replace(s, ~r/\D/, "")
    end
  end

  # ---- generic sanitizers ----
  defp clean(nil), do: ""
  defp clean(v) when is_binary(v), do: String.trim(v)
  defp clean(v), do: v |> to_string() |> String.trim()

  defp provided?(nil), do: false
  defp provided?(""), do: false
  defp provided?(v) when is_binary(v), do: String.trim(v) != ""
  defp provided?(_), do: true

  defp to_nonneg_decimal(v) when is_integer(v), do: to_nonneg_decimal(Decimal.new(v))
  defp to_nonneg_decimal(v) when is_float(v), do: to_nonneg_decimal(Decimal.from_float(v))

  defp to_nonneg_decimal(%Decimal{} = d) do
    case Decimal.cmp(d, 0) do
      :lt -> {:error, "Remaining leave days cannot be negative"}
      _ -> {:ok, Decimal.round(d, 2)}
    end
  end

  defp to_nonneg_decimal(v) when is_binary(v) do
    s = v |> String.trim() |> String.replace(",", "")
    case Decimal.parse(s) do
      {:ok, d} -> to_nonneg_decimal(d)
      :error -> {:error, "Invalid decimal #{inspect(v)}"}
    end
  end

  defp to_nonneg_decimal(other), do: {:error, "Unsupported value #{inspect(other)}"}

  defp normalize(nil), do: ""
  defp normalize(term) do
    term
    |> to_string()
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[_\s]+/u, " ")
  end
end

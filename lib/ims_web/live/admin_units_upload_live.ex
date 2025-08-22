defmodule ImsWeb.AdminUnitsUploadLive do
  use ImsWeb, :live_view

  alias Ims.Regions
  alias Ims.Repo
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    Logger.info("[AdminUnitsUploadLive] mount/3")

    {:ok,
     socket
     |> assign(imported: 0, errors: [], info: nil)
     |> allow_upload(:sheet,
       accept: ~w(.xlsx .csv),
       max_entries: 1,
       max_file_size: 10_000_000,
       auto_upload: true
     )}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    Logger.info(
      "[AdminUnitsUploadLive] handle_event validate — entries=#{length(socket.assigns.uploads.sheet.entries)}"
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    Logger.info(
      "[AdminUnitsUploadLive] handle_event save — attempting to consume uploaded entries"
    )

    {completed, still_in_progress} = uploaded_entries(socket, :sheet)

    Logger.info(
      "[AdminUnitsUploadLive] completed=#{length(completed)} still_in_progress=#{length(still_in_progress)}"
    )

    if completed == [] do
      info = nil
      errors = ["Upload is still in progress. Wait for 100% then click Import."]
      {:noreply, assign(socket, imported: 0, errors: errors, info: info)}
    else
      {count, errors} =
        consume_uploaded_entries(socket, :sheet, fn %{path: path}, entry ->
          name = String.downcase(entry.client_name || "")
          Logger.info("[AdminUnitsUploadLive] consuming #{inspect(name)} at #{path}")

          try do
            rows =
              cond do
                String.ends_with?(name, ".xlsx") -> read_xlsx(path)
                String.ends_with?(name, ".csv") -> read_csv(path)
                true -> raise "Unsupported file type: #{name}"
              end

            {imported, errs} = import_rows(rows)
            {:ok, {imported, errs}}
          rescue
            e ->
              Logger.error(Exception.format(:error, e, __STACKTRACE__))
              {:ok, {0, ["#{name}: #{Exception.message(e)}"]}}
          end
        end)
        |> Enum.reduce({0, []}, fn {imp, err}, {acc_i, acc_e} -> {acc_i + imp, acc_e ++ err} end)

      info =
        if count > 0 and Enum.empty?(errors) do
          "Imported #{count} rows."
        else
          nil
        end

      {:noreply, assign(socket, imported: count, errors: errors, info: info)}
    end
  end

  # ---------- Parsers ----------

  # Expect header row with ["County", "Constituency", "Ward"] (case-insensitive; extra cols OK)
  defp read_xlsx(path) do
    case Xlsxir.multi_extract(path, 0) do
      {:ok, tid} ->
        data = Xlsxir.get_list(tid)
        Xlsxir.close(tid)
        data

      other ->
        raise "XLSX read error: #{inspect(other)}"
    end
  end

  defp read_csv(path) do
    path
    |> File.stream!()
    |> NimbleCSV.RFC4180.parse_stream()
    |> Enum.to_list()
  end

  # rows :: [header | data...]
defp import_rows([raw_header | rows]) do
  header = Enum.map(List.wrap(raw_header), &cell_to_string/1)
  {county_idx, const_idx, ward_idx} = find_columns(header)

  # Clean & normalize all rows
  parsed =
    rows
    |> Enum.map(fn raw_row ->
      row = Enum.map(List.wrap(raw_row), &cell_to_string/1)

      {
        clean(Enum.at(row, county_idx)),
        clean(Enum.at(row, const_idx)),
        clean(Enum.at(row, ward_idx))
      }
    end)
    |> Enum.reject(fn {c, k, w} -> c == "" and k == "" and w == "" end)

  # 1. Counties
  county_names =
    parsed |> Enum.map(fn {c, _ , _} -> c end) |> Enum.uniq() |> Enum.reject(&(&1 == ""))

  county_map =
    Enum.reduce(county_names, %{}, fn name, acc ->
      c = Regions.upsert_county!(name)
      Map.put(acc, name, c.id)
    end)

  # 2. Constituencies
  const_pairs =
    parsed
    |> Enum.map(fn {c, k, _} -> {c, k} end)
    |> Enum.uniq()
    |> Enum.reject(fn {_c, k} -> k == "" end)

  const_map =
    Enum.reduce(const_pairs, %{}, fn {cname, constname}, acc ->
      case Map.get(county_map, cname) do
        nil -> acc
        cid ->
          cc = Regions.upsert_constituency!(cid, constname)
          Map.put(acc, {cname, constname}, cc.id)
      end
    end)

  # 3. Wards
  ward_triples =
    parsed
    |> Enum.map(fn {c, k, w} -> {c, k, w} end)
    |> Enum.uniq()
    |> Enum.reject(fn {_c, _k, w} -> w == "" end)

  Enum.each(ward_triples, fn {cname, constname, wardname} ->
    with cid when not is_nil(cid) <- Map.get(county_map, cname),
         ccid when not is_nil(ccid) <- Map.get(const_map, {cname, constname}) do
      _w = Regions.upsert_ward!(ccid, wardname)
    end
  end)

  {length(ward_triples), []}
end

defp import_rows(_), do: {0, ["Empty file or missing header"]}
  defp find_columns(header) do
    norm = fn v -> v |> to_string() |> String.downcase() |> String.trim() end
    names = Enum.with_index(header, fn v, i -> {norm.(v), i} end) |> Map.new()

    county_idx = Map.get(names, "county") || raise "Missing 'County' column"
    const_idx = Map.get(names, "constituency") || raise "Missing 'Constituency' column"
    ward_idx = Map.get(names, "ward") || raise "Missing 'Ward' column"
    {county_idx, const_idx, ward_idx}
  end

  defp cell_to_string(nil), do: ""
  defp cell_to_string(v) when is_binary(v), do: v
  defp cell_to_string(v), do: to_string(v)

  defp clean(v), do: v |> to_string() |> String.trim()

  # Public so template can call module-qualified (or call unqualified if you prefer)
  def uploads_ready?(entries) when is_list(entries) do
    entries != [] and
      Enum.all?(entries, fn e ->
        Map.get(e, :done?, false) or Map.get(e, :progress, 0) == 100
      end)
  end
end

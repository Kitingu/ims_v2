defmodule Ims.Helpers do
  def format_currency(%Decimal{} = amount) do
    amount
    # Convert Decimal to string with full precision
    |> Decimal.to_string(:normal)
    |> format_currency_string()
  end

  def format_currency(amount) when is_float(amount) or is_integer(amount) do
    amount
    # Ensure 2 decimal places for floats
    |> :erlang.float_to_binary(decimals: 2)
    |> format_currency_string()
  end

  defp format_currency_string(amount_string) do
    amount_string
    # Add comma separators
    |> String.replace(~r/(\d)(?=(\d{3})+\.)/, "\\1,")
    # Prepend "KES"
    |> then(&"KES #{&1}")
  end

  def humanize_date(date),
    do:
      date
      |> to_string()
      |> Timex.parse!("%Y-%m-%d", :strftime)
      |> Timex.format!("{Mshort} {0D}, {YYYY}")

  def humanize_datetime(datetime) when datetime in [nil, ""], do: nil

  def humanize_datetime(datetime) do
    datetime |> Timex.format!("{Mshort} {0D}, {YYYY} at {h12}:{m}{am}")
  end

  #  def generate_qr_code(qr_content) do
  #    qr_content
  #    |> EQRCode.encode()
  #    |> EQRCode.svg(color: "#000", width: 105, background: "#FFF")
  #    |> render_svg()
  #  end

  def validate_phone_number(nil), do: false

  def validate_phone_number(phone_number) when is_integer(phone_number) do
    phone_number
    |> Integer.to_string()
    |> validate_phone_number()
  end

  def validate_phone_number(phone_number) do
    # (r"^(?:254|\+254|0)?(7(?:(?:[129][0-9])|(?:0[0-8])|(4[0-1]))[0-9]{6})$", phone_number):
    # implement this regex

    # regex = ~r/^(?:254|\+254|0)?(7(?:(?:[129][0-9])|(?:0[0-8])|(4[0-1]))[0-9]{6})$/
    regex = ~r/^(?:254|\+254|0)?(7[0-9]{8}|1[0-9]{8})$/


    case Regex.match?(regex, phone_number) do
      true -> true
      false -> false
    end
  end

  def normalize_phone_number(phone_number) do
    cond do
      String.starts_with?(phone_number, "254") ->
        String.replace(phone_number, "254", "0")

      String.starts_with?(phone_number, "+254") ->
        String.replace(phone_number, "+254", "0")

      String.starts_with?(phone_number, "0") ->
        phone_number

      true ->
        "0" <> phone_number
    end
  end

  def atomize?(%Decimal{} = val) do
    val
  end

  def atomize?(%NaiveDateTime{} = val) do
    val
  end

  def atomize?(val) when is_struct(val) do
    val
    |> Map.from_struct()
    |> Map.drop([:__meta__, :__cardinality__, :__field__, :__owner__])
    |> atomize?()
  end

  def atomize?(val) when is_map(val) do
    Enum.map(val, fn {k, v} ->
      {is_atom?(k), atomize?(v)}
    end)
    |> Enum.into(%{})
  end

  def atomize?([_ | _] = val) do
    val |> Enum.map(&atomize?(&1))
  end

  def atomize?(val), do: val

  defp is_atom?(key) when is_atom(key), do: key

  defp is_atom?(key) when is_binary(key) do
    String.to_atom(key)
  end

  #  defp render_svg("<?xml version=\"1.0\" standalone=\"yes\"?>" <> svg) do
  #    svg
  #  end

  def convert_tz(datetime) do
    datetime
    |> Timex.to_datetime()
    |> DateTime.shift_zone!(Timex.Timezone.Local.lookup())
  end

  # convert default utc timezone to client timezone
  def convert_tz(datetime, timezone) do
    datetime
    |> DateTime.from_naive!("Greenwich")
    |> Timex.Timezone.convert(timezone)
  end

  @kb 1024
  @mb 1024 * @kb
  @gb 1024 * @mb

  @doc """
  Converts file size in bytes to human-readable format (KB, MB, or GB).
  """
  def to_human_readable_file_size(size_in_bytes) do
    cond do
      size_in_bytes >= @gb ->
        gb = size_in_bytes / @gb
        "#{Float.round(gb, 2)} GB"

      size_in_bytes >= @mb ->
        mb = size_in_bytes / @mb
        "#{Float.round(mb, 2)} MB"

      size_in_bytes >= @kb ->
        kb = size_in_bytes / @kb
        "#{Float.round(kb, 2)} KB"

      true ->
        "#{size_in_bytes} bytes"
    end
  end
end

defmodule Ims.Helpers.Holidays do
  @moduledoc """
  Checks for holidays using:
  - Hardcoded Kenyan holidays
  - Google Calendar's public Kenyan holiday feed
  """

  # Hardcoded Kenyan public holidays (day/month tuples)
  @hardcoded_holidays [
    # New Year
    {1, 1},
    # Labor Day
    {1, 5},
    # Madaraka Day
    {1, 6},
    # Utamaduni Day
    {10, 10},
    # Mashujaa Day
    {20, 10},
    # Christmas
    {25, 12},
    # Boxing Day
    {26, 12}
  ]

  # Google Calendar's public iCal feed for Kenyan holidays
  @ical_url "https://calendar.google.com/calendar/ical/en.ke%23holiday%40group.v.calendar.google.com/public/basic.ics"

  @doc """
  Check if a date is a holiday (accepts Date, string "DD-MM-YYYY", or "DD-MM--YYYY" typo)
  """
  def is_holiday?(date_str) when is_binary(date_str) do
    case parse_date(date_str) do
      {:ok, date} -> is_holiday?(date)
      _ -> false
    end
  end

  def is_holiday?(%Date{} = date) do
    is_hardcoded_holiday?(date) or is_google_calendar_holiday?(date)
  end

  def is_holiday?(_), do: false

  # -- Helper functions -- #

  defp is_hardcoded_holiday?(date) do
    Enum.any?(@hardcoded_holidays, fn {day, month} ->
      date.day == day and date.month == month
    end)
  end

  defp is_google_calendar_holiday?(date) do
    case fetch_holidays() do
      {:ok, holidays} -> Enum.any?(holidays, &(Date.compare(date, &1) == :eq))
      _ -> false
    end
  end

  defp fetch_holidays do
    # Use HTTPoison instead of Req (more commonly available)
    case HTTPoison.get(@ical_url) do
      {:ok, %{body: body}} ->
        holidays =
          body
          |> String.split("\n")
          |> Enum.filter(&String.starts_with?(&1, "DTSTART;VALUE=DATE:"))
          |> Enum.map(fn line ->
            line
            |> String.replace("DTSTART;VALUE=DATE:", "")
            |> parse_ical_date()
          end)
          |> Enum.reject(&is_nil/1)

        {:ok, holidays}

      _ ->
        :error
    end
  end

  # Parse iCal format (YYYYMMDD)
  defp parse_ical_date(<<y1, y2, y3, y4, m1, m2, d1, d2>>) do
    with {year, ""} <- Integer.parse("#{y1}#{y2}#{y3}#{y4}"),
         {month, ""} <- Integer.parse("#{m1}#{m2}"),
         {day, ""} <- Integer.parse("#{d1}#{d2}"),
         {:ok, date} <- Date.new(year, month, day) do
      date
    else
      _ -> nil
    end
  end
  defp parse_ical_date(_), do: nil

  # Parse "DD-MM-YYYY" or "DD-MM--YYYY" (with typo)
  defp parse_date(date_str) do
    date_str
    |> String.replace("--", "-") # Fix double hyphen typo
    |> String.split("-")
    |> case do
      [day, month, year] ->
        with {day, ""} <- Integer.parse(day),
             {month, ""} <- Integer.parse(month),
             {year, ""} <- Integer.parse(year),
             {:ok, date} <- Date.new(year, month, day) do
          {:ok, date}
        else
          _ -> :error
        end
      _ -> :error
    end
  end
end

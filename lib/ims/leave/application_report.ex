defmodule Ims.Leave.ApplicationReport do
  import Ecto.Query
  alias Swoosh.Email

  alias Ims.Leave.LeaveApplication
  alias Ims.{Mailer, Repo}

  def deliver(recipient, filters) do
    case Application.get_env(:ims, :mailer_from_email) do
      sender when is_binary(sender) and sender != "" ->
        Email.new()
        |> Email.from({Application.get_env(:ims, :mailer_from_name, "IMS"), sender})
        |> Email.to(recipient)
        |> Email.subject("IMS leave application summary")
        |> Email.text_body(summary(filters))
        |> Mailer.deliver()

      _ ->
        {:error, :sender_not_configured}
    end
  end

  defp summary(filters) do
    query = filters |> LeaveApplication.search() |> exclude(:preload)

    rows =
      from(application in query,
        group_by: application.status,
        order_by: application.status,
        select: {application.status, count(application.id), sum(application.days_requested)}
      )
      |> Repo.all()

    totals =
      Enum.map_join(rows, "\n", fn {status, count, days} ->
        "#{status}: #{count} applications, #{days || 0} requested days"
      end)

    """
    Leave applications overlapping the reporting period

    Period start: #{filters["from"] || "Any"}
    Period end: #{filters["to"] || "Any"}
    Status: #{filters["status"] |> present_or_all()}
    Employee ID: #{filters["user_id"] |> present_or_all()}

    #{if totals == "", do: "No matching applications.", else: totals}

    Requested days are totals for the full matching applications.
    """
  end

  defp present_or_all(value) when value in [nil, ""], do: "All"
  defp present_or_all(value), do: value
end

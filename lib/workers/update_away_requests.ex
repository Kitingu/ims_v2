defmodule Ims.Workers.AwayRequestStatusUpdaterWorker do
  use Oban.Worker, queue: :default, max_attempts: 1

  import Ecto.Query
  alias Ims.{Repo, HR.AwayRequest}

  @impl true
  def perform(_args, _job) do
    today = Date.utc_today()

    from(a in AwayRequest,
      where: a.return_date <= ^today and a.status == "active"
    )
    |> Repo.update_all(set: [status: "returned"])

    :ok
  end
end

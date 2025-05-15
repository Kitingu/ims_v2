defmodule Ims.Workers.Welfare.MemberRefreshWorkers do
  use Oban.Worker, queue: :welfare, max_attempts: 3

  alias Ims.Repo
  alias Ims.Welfare
  import Ecto.Query

  @batch_size 100

  # ----------------------------
  # Dispatcher Worker Function
  # ----------------------------
  def perform(%Oban.Job{args: %{"job_type" => "dispatch"}}) do


    query = from(m in Welfare.Member, where: m.status == "active", select: m.id)

    Repo.stream(query, max_rows: @batch_size)
    |> Stream.chunk_every(@batch_size)
    |> Enum.each(fn member_ids ->
      %{job_type: "batch", member_ids: member_ids}
      |> __MODULE__.new()
      |> Oban.insert()
    end)

    :ok
  end

  # ----------------------------
  # Batch Worker Function
  # ----------------------------
  def perform(%Oban.Job{args: %{"job_type" => "batch", "member_ids" => member_ids}}) do
    from(m in Welfare.Member, where: m.id in ^member_ids)
    |> Repo.all()
    |> Enum.each(&Welfare.refresh_member_balance/1)

    :ok
  end
end

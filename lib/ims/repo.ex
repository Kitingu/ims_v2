defmodule Ims.Repo do
  use Ecto.Repo,
    otp_app: :ims,
    adapter: Ecto.Adapters.Postgres
    # pagination
    use Scrivener, page_size: 10
end

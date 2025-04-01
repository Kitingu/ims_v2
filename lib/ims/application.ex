defmodule Ims.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ImsWeb.Telemetry,
      Ims.Repo,
      {DNSCluster, query: Application.get_env(:ims, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Ims.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Ims.Finch},
      # Start a worker by calling: Ims.Worker.start_link(arg)
      # {Ims.Worker, arg},
      # Start to serve requests, typically the last entry
      ImsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ims.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ImsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

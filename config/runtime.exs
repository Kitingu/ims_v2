import Config

# Enable the HTTP server when running a release.
if System.get_env("PHX_SERVER") in ~w(true 1) do
  config :ims, ImsWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "Missing DATABASE_URL"

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "Missing SECRET_KEY_BASE. Generate one using: mix phx.gen.secret"

  host = System.get_env("PHX_HOST") || "ims.deputypresident.go.ke"
  http_port = String.to_integer(System.get_env("PORT") || "4000")
  https_port = String.to_integer(System.get_env("HTTPS_PORT") || "443")

  maybe_ipv6 =
    if System.get_env("ECTO_IPV6") in ~w(true 1),
      do: [:inet6],
      else: []

  # PostgreSQL runs locally on the Konza server.
  config :ims, Ims.Repo,
    ssl: false,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6,
    queue_target: 5000,
    queue_interval: 5000

  # Optional SMTP configuration. SendGrid remains configured in prod.secrets.exs.
  # config :ims, Ims.Mailer,
  #   adapter: Swoosh.Adapters.SMTP,
  #   relay: System.get_env("SMTP_RELAY") || "smtp.gmail.com",
  #   username: System.get_env("GMAIL_USERNAME"),
  #   password: System.get_env("GMAIL_APP_PASSWORD"),
  #   port: String.to_integer(System.get_env("GMAIL_PORT") || "587"),
  #   ssl: false,
  #   tls: :always,
  #   auth: :always

  # Direct HTTPS remains available when certificate paths are supplied.
  https_config =
    if System.get_env("SSL_KEY_PATH") && System.get_env("SSL_CERT_PATH") do
      [
        https: [
          port: https_port,
          cipher_suite: :strong,
          keyfile: System.get_env("SSL_KEY_PATH"),
          certfile: System.get_env("SSL_CERT_PATH")
        ],
        force_ssl: [hsts: true]
      ]
    else
      []
    end

  # Nginx handles public HTTPS and forwards requests to this local listener.
  config :ims,
         ImsWeb.Endpoint,
         [
           url: [host: host, port: 443, scheme: "https"],
           http: [
             ip: {127, 0, 0, 1},
             port: http_port
           ],
           secret_key_base: secret_key_base,
           cache_static_manifest: "priv/static/cache_manifest.json",
           check_origin: [
             "http://localhost:4000",
             "http://127.0.0.1:4000",
             "http://#{host}:4000",
             "http://#{host}",
             "https://#{host}"
           ]
         ] ++ https_config

  config :ims, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :swoosh,
    api_client: Swoosh.ApiClient.Finch,
    finch_name: Ims.Finch

  config :swoosh, local: false

  config :logger, level: :info
end

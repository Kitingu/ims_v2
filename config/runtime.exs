import Config

# Enable server in releases
if System.get_env("PHX_SERVER") do
  config :ims, ImsWeb.Endpoint, server: true
end

if config_env() == :prod do
  # Required ENV vars
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "Missing DATABASE_URL. Example: ecto://USER:PASS@HOST/DATABASE"

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "Missing SECRET_KEY_BASE. Generate one using: mix phx.gen.secret"

  host = System.get_env("PHX_HOST") || "ims-app.co.ke"
  http_port = String.to_integer(System.get_env("PORT") || "4000")
  https_port = String.to_integer(System.get_env("HTTPS_PORT") || "443")

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  # Repo configuration
  config :ims, Ims.Repo,
    ssl: true,
    ssl_opts: [verify: :verify_none],
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6,
    queue_target: 5000,
    queue_interval: 5000

  # Configure the mailer
  # config :ims, Ims.Mailer,
  #   adapter: Swoosh.Adapters.SMTP,
  #   relay: System.get_env("SMTP_RELAY") || "smtp.gmail.com",
  #   username: System.get_env("GMAIL_USERNAME"),
  #   password: System.get_env("GMAIL_APP_PASSWORD"),
  #   port: String.to_integer(System.get_env("GMAIL_PORT") || "587"),
  #   ssl: false,
  #   tls: :always,
  #   auth: :always

  # Optional HTTPS config block
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

  # Endpoint config
  config :ims,
         ImsWeb.Endpoint,
         [
           url: [host: host, port: http_port, scheme: "http"],
           http: [
             ip: {0, 0, 0, 0},
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
         ] ++
           https_config

  # DNS clustering (optional)
  config :ims, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  # Swoosh mailer (optional)
  config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Ims.Finch
  config :swoosh, local: false

  # Logging
  config :logger, level: :info
end

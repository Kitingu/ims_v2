# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ims,
  ecto_repos: [Ims.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :ims, ImsWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ImsWeb.ErrorHTML, json: ImsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Ims.PubSub,
  live_view: [signing_salt: "XFHzw63R"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
# config :ims, Ims.Mailer, adapter: Swoosh.Adapters.Local

config :ims, Ims.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: "smtp.gmail.com",
  username: "kitingu11@gmail.com",
  password: "ocxteshxatrzrinh",
  port: 587,
  ssl: false,
  tls: :always,
  tls_options: [verify: :verify_none],
  auth: :always

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  ims: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  ims: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# config :ims, Oban,
#   repo: Ims.Repo,
#   plugins: [
#     Oban.Plugins.Pruner,
#     {Oban.Plugins.Cron,
#      crontab: [
#        # Every 2 minutes
#        {"*/2 * * * *", Ims.Workers.LeaveAccrualWorker, args: %{"type" => "monthly"}},

#        # Still run year_end annually
#        {"0 1 1 1 *", Ims.Workers.LeaveAccrualWorker, args: %{"type" => "year_end"}}
#      ]}
#   ],
#   queues: [default: 10]

config :ims, Oban,
  repo: Ims.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       # Run on the 1st of every month at 1 AM
       {"0 1 1 * *", Ims.Workers.LeaveAccrualWorker, args: %{"type" => "monthly"}},

       # Run on Jan 1st every year at 1 AM
       {"0 1 1 1 *", Ims.Workers.LeaveAccrualWorker, args: %{"type" => "year_end"}}
     ]}
  ],
  queues: [default: 10, welfare: 2]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

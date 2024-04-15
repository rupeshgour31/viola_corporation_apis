# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :violacorp,
  ecto_repos: [Violacorp.Repo]

# Configures the endpoint
config :violacorp, ViolacorpWeb.Endpoint,
  url: [host: "ec2-18-130-2-245.eu-west-2.compute.amazonaws.com"],
  secret_key_base: "6ctwmJguCD8mYX7y3bqtghyy04XkRF1qI3XPPBSkYUmX2bNhExIBJcgSUvKv2gy6",
  render_errors: [view: ViolacorpWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Violacorp.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
#config :logger, :console,
#       format: "$time $metadata[$level] $message\n",
#       metadata: [:user_id]

config :logger,
       format: "$metadata[$level] $message\n",
       backends: [:console, CloudWatch],
       utc_log: true

# Configures Bamboo mailer
#config :violacorp, Violacorp.Mailer,
#       adapter: Bamboo.MailgunAdapter,
#       api_key: System.get_env("BAMBOO_API_KEY")
#       domain: "violacorporate.com"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
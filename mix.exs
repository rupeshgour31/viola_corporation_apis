defmodule Violacorp.Mixfile do
  use Mix.Project

  def project do
    [
      app: :violacorp,
      version: "0.0.2",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Violacorp.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :phoenix_ecto,
        :redix,
        :httpoison,
        :scrivener_ecto,
        :exq,
        :edeliver,
        :cloud_watch,
        :cachex,
        :elixir_xml_to_map
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.4"},
      {:phoenix_pubsub, "~> 1.0"},
      {:ecto, "~> 2.2"},
      {:phoenix_ecto, "~> 3.4.0"},
      {:mariaex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.10"},
      {:gettext, "~> 0.11"},
      {:cowboy, ">= 0.0.0"},
      {:plug_cowboy, ">= 0.0.0"},
      {:pigeon, "~> 1.2"},
      {:kadabra, "~> 0.4.4"},
      {:bamboo, "~> 0.8"},
      {:bamboo_smtp, "~> 1.4.0"},
      {:exq, "~> 0.12.2"},
      {:redix, ">= 0.0.0"},
      {:httpoison, "~> 0.13", override: true},
      {:scrivener_ecto, "~> 1.0"},
      {:exq_ui, "~> 0.9.0"},
      {:cloak, "~> 0.5.0"},
      {:cors_plug, "~> 1.5"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:iteraptor, "~> 1.2.1"},
      {:quantum, "~> 2.3.3"},
      {:csv, "~> 2.0.0"},
      {:decimal, "~> 1.0"},
      {:timex, "~> 3.0"},
      {:edeliver, "~> 1.8"},
      {:cloud_watch, "~> 0.3.0"},
      {:distillery, "~> 2.1", warn_missing: false},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:benchee, "~> 0.11", only: :dev},
      {:credo, "~> 0.9.0-rc1", only: [:dev, :test], runtime: false},
      {:cachex, "~> 3.1"},
      {:elixir_xml_to_map, "~> 0.1"},
      {:mogrify, "~> 0.7.3"}

    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
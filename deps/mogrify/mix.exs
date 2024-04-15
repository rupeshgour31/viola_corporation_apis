defmodule Mogrify.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mogrify,
      version: "0.7.3",
      elixir: ">= 1.2.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:crypto, :logger]]
  end

  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp description do
    "ImageMagick command line wrapper."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "CHANGELOG*", "LICENSE*"],
      maintainers: ["Dmitry Vorotilin", "Andrew Shu"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/route/mogrify"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end

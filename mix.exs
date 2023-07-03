defmodule PhoenixHelpers.MixProject do
  use Mix.Project

  @source_url "https://github.com/elielhaouzi/phoenix_helpers"
  @version "0.8.1"

  def project do
    [
      app: :phoenix_helpers,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:phoenix, "~> 1.6"},
      {:jason, "~> 1.0", only: [:test]},
      {:ecto, "~> 3.0"}
    ]
  end

  defp description() do
    """
    A Small collection of functions to make easier render schema's fields with its associations.
    """
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: [
        "README.md"
      ]
    ]
  end
end

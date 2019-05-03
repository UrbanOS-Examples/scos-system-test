defmodule ScosSystemTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :scos_system_test,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: StreamingDataAggregator.CLI]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :faker],
      applications: [:httpoison]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:httpoison, "~> 1.5"},
      {:patiently, "~> 0.2", only: [:dev, :test, :integration]},
      {:jason, "~> 1.1"},
      {:elixir_uuid, "~> 1.2"},
      {:csv, "~> 2.3"},
      {:faker, "~> 0.12"},
      {:hackney, "~> 1.15"},
      {:sweet_xml, "~> 0.6"},
      {:configparser_ex, "~> 2.0"},
      {:smart_city_registry, "~> 2.6", organization: "smartcolumbus_os"},
      {:smart_city_test, "~> 0.2.3", organization: "smartcolumbus_os"}
    ]
  end
end

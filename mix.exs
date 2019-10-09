defmodule ScosSystemTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :scos_system_test,
      version: "0.1.1",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_paths: test_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :faker, :httpoison]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:httpoison, "~> 1.5"},
      {:patiently, "~> 0.2"},
      {:jason, "~> 1.1"},
      {:elixir_uuid, "~> 1.2"},
      {:csv, "~> 2.3"},
      {:faker, "~> 0.12"},
      {:hackney, "~> 1.15"},
      {:sweet_xml, "~> 0.6"},
      {:configparser_ex, "~> 4.0"},
      # can take out override when registry is no longer used
      {:smart_city, "~> 3.0", override: true},
      {:smart_city_registry, "~> 5.0"},
      {:smart_city_test, "~> 0.5.3"},
      {:prestige, "~> 0.3.1"},
      {:placebo, "~> 1.2", only: [:dev, :test]}
    ]
  end

  defp test_paths(:system), do: ["test/system"]
  defp test_paths(_), do: ["test/unit"]
end

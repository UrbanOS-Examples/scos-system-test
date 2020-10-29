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

  def application do
    [
      extra_applications: [:logger, :faker, :httpoison]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.1.5", only: [:dev, :test], runtime: false},
      {:brod, "~> 3.14.0"},
      {:phoenix_gen_socket_client, "~> 2.1.1"},
      {:websocket_client, "~> 1.2"},
      {:poison, "~> 2.0"},
      {:httpoison, "~> 1.5"},
      {:patiently, "~> 0.2"},
      {:jason, "~> 1.1"},
      {:elixir_uuid, "~> 1.2"},
      {:csv, "~> 2.3"},
      {:faker, "~> 0.12"},
      {:hackney, "~> 1.16"},
      {:sweet_xml, "~> 0.6"},
      {:configparser_ex, "~> 4.0"},
      {:smart_city, "~> 3.0"},
      {:smart_city_test, "~> 0.10"},
      {:prestige, "~> 1.0"},
      {:websockex, "~> 0.4.0"},
      {:placebo, "~> 1.2", only: [:dev, :test]}
    ]
  end

  defp test_paths(:system), do: ["test/system"]
  defp test_paths(_), do: ["test/unit"]
end

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
      extra_applications: [:logger],
      applications: [:httpoison]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.5"},
      {:patiently, "~> 0.2.0", only: [:dev, :test, :integration]},
      {:jason, "~> 1.1"},
      {:elixir_uuid, "~> 1.2"},
      {:csv, "~> 2.0.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_aws, "~> 2.0.0"},
      {:faker, "~> 0.12", only: [:test, :integration]},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"},
      {:configparser_ex, "~> 2.0"},
      {:ex_aws_sts, "~> 2.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end

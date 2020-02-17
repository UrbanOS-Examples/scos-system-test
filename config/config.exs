use Mix.Config

config :scos_system_test,
  discovery_url: "https://data.staging.internal.smartcolumbusos.com",
  default_andi_url: "https://andi.staging.internal.smartcolumbusos.com",
  default_tdg_url: "http://data-generator.testing"

config :prestige, :session_opts,
  url: "https://presto.staging.internal.smartcolumbusos.com",
  catalog: "hive",
  schema: "default",
  user: "scos-system-test"

config :logger,
  level: :info,
  compile_time_purge_level: :debug

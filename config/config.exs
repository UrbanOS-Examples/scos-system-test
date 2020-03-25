use Mix.Config

environment = "staging"

config :scos_system_test,
  discovery_url: "https://data.#{environment}.internal.smartcolumbusos.com",
  discovery_streams_url: "wss://streams.#{environment}.internal.smartcolumbusos.com/socket/websocket",
  default_andi_url: "https://andi.#{environment}.internal.smartcolumbusos.com",
  default_tdg_url: "http://data-generator.testing"

config :prestige, :session_opts,
  url: "https://presto.#{environment}.internal.smartcolumbusos.com",
  catalog: "hive",
  schema: "default",
  user: "scos-system-test"

config :logger,
  level: :info,
  compile_time_purge_level: :debug

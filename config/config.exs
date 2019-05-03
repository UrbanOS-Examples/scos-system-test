# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :scos_system_test,
  discovery_url: "https://data.staging.internal.smartcolumbusos.com",
  default_andi_url: "https://andi.staging.internal.smartcolumbusos.com",
  default_tdg_url: "http://data-generator.testing"

#     import_config "#{Mix.env()}.exs"

# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ex_aws,
  region: "us-east-1",
  access_key_id: [
    {:system, "AWS_ACCESS_KEY_ID"},
    :instance_role
  ],
  secret_access_key: [
    {:system, "AWS_SECRET_ACCESS_KEY"},
    :instance_role
  ],
  debug_requests: true,
  json_codec: Jason

#     import_config "#{Mix.env()}.exs"

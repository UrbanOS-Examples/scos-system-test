defmodule ScosSystemTest do
  use ExUnit.Case
  @moduletag timeout: 1_200_000
  require Logger
  import SystemLib

  @temp_file_path "./tmp_file"

  @andi_url Application.get_env(:scos_system_test, :andi_url)
  @discovery_url Application.get_env(:scos_system_test, :discovery_url)

  setup do
    File.rm(@temp_file_path)

    :ok
  end

  test "greets the world" do
    uuid = UUID.uuid1() |> String.replace("-", "_")
    Logger.info("Starting System Test with id: #{uuid}")

    message_count = 10

    message_count
    |> generate_messages()
    |> CSV.encode()
    |> write_csv(File.open!(@temp_file_path, [:append, :utf8]))

    send_to_bucket(@temp_file_path, "scos-system-test", "system-test-#{uuid}.csv")

    HTTPoison.put!(
      "#{@andi_url}/dataset",
      generate_body(uuid),
      [{"content-type", "application/json"}]
    )

    Patiently.wait_for!(
      discovery_query(uuid, message_count),
      dwell: 10_000,
      max_tries: 60
    )
  end

  defp discovery_query(uuid, message_count) do
    fn ->
      url = "#{@discovery_url}/dataset/#{uuid}/preview"

      actual = HTTPoison.get(url) |> handle_response()

      Logger.info("Waiting for #{length(actual)} messages, got #{message_count}")

      try do
        assert length(actual) == message_count
        true
      rescue
        _ -> false
      end
    end
  end
end

defmodule ScosSystemTest do
  use ExUnit.Case
  @moduletag timeout: 1_200_000
  alias ScosSystemTest.Helpers
  alias ScosSystemTest.StreamClient

  require Logger

  @temp_file_path "./tmp_file"
  # @discovery_url Application.get_env(:scos_system_test, :discovery_url)
  @discovery_streams_url Application.get_env(:scos_system_test, :discovery_streams_url)
  @default_andi_url Application.get_env(:scos_system_test, :default_andi_url)
  @default_tdg_url Application.get_env(:scos_system_test, :default_tdg_url)

  setup do
    File.rm(@temp_file_path)
    uuid = Helpers.generate_uuid()

    Logger.info("Starting System Test with Dataset Id: #{uuid}")

    on_exit(fn ->
      Helpers.delete_dataset(uuid, @default_andi_url)
    end)

    organization =
      Helpers.generate_organization(uuid)
      |> Helpers.upload_organization(@default_andi_url)

    Logger.info("Organization: #{inspect(organization)}")

    [uuid: uuid, organization: organization]
  end

  test "creates an ingest dataset", %{
    uuid: uuid,
    organization: organization
  } do
    record_count = 10

    dataset =
      Helpers.generate_dataset(uuid, organization, record_count, @default_tdg_url)
      |> create_dataset()

    wait_for_data_to_appear_in_presto(dataset.technical.systemName, record_count, true)
  end

  test "creates a streaming dataset and sees data in the stream", %{
    uuid: uuid,
    organization: organization
  } do
    record_count = 2

    streaming_dataset =
      Helpers.generate_dataset(uuid, organization, record_count, @default_tdg_url, %{
        cadence: "*/15 * * * * *",
        sourceType: "stream"
      })
      |> create_dataset()

    stream_topic = "streaming:#{streaming_dataset.technical.systemName}"
    {:ok, pid} = StreamClient.start_link(@discovery_streams_url)
    StreamClient.join_topic(pid, stream_topic)

    wait_for_data_to_appear_in_the_stream(stream_topic, record_count)
    wait_for_data_to_appear_in_presto(streaming_dataset.technical.systemName, record_count, false)
  end

  defp wait_for_data_to_appear_in_presto(system_name, count, require_precise_record_count) do
    Patiently.wait_for!(
      presto_query(system_name, count, require_precise_record_count),
      dwell: 6_000,
      max_tries: 50
    )
  end

  defp wait_for_data_to_appear_in_the_stream(stream_topic, count) do
    Patiently.wait_for!(
      stored_messages_exceed_count(stream_topic, count),
      dwell: 6_000,
      max_tries: 50
    )
  end

  defp stored_messages_exceed_count(stream_topic, expected_count) do
    fn ->
      try do
        message_count =
          :ets.tab2list(String.to_existing_atom(stream_topic))
          |> Enum.map(fn {_, message} -> message end)
          |> Enum.filter(fn message -> Map.has_key?(message, "quantity") end)
          |> Enum.count()

        assert message_count >= expected_count
        Logger.info("Expected number of records on the stream was met or exceeded")
        true
      rescue
        error ->
          Logger.debug(Exception.format(:error, error, __STACKTRACE__))
          false
      end
    end
  end

  defp presto_query(system_name, message_count, require_precise_record_count) do
    fn ->
      try do
        {:ok, %{rows: [[count]]}} =
          "select count(1) from #{system_name}__json"
          |> Helpers.execute()

        if require_precise_record_count do
          assert count == message_count
          Logger.info("Expected number of records found in Presto")
        else
          assert count >= message_count
          Logger.info("At least the number of records required were found in Presto")
        end

        true
      rescue
        error ->
          Logger.debug(Exception.format(:error, error, __STACKTRACE__))
          false
      end
    end
  end

  defp create_dataset(proposed_dataset) do
    Logger.debug("Creating Dataset: #{inspect(proposed_dataset)}")

    with dataset_map <- Helpers.upload_dataset(proposed_dataset, @default_andi_url),
         {:ok, dataset} <- SmartCity.Dataset.new(dataset_map) do
      Logger.info(
        "Created dataset #{dataset.business.dataTitle} with system name: #{
          dataset.technical.systemName
        }"
      )

      dataset
    else
      {:error, error} -> raise error
    end
  end

  ## Held in stasis until the EOF work is done
  # defp wait_for_data_to_appear_in_discovery(uuid, count) do
  #   Patiently.wait_for!(
  #     discovery_query(uuid, count),
  #     dwell: 6_000,
  #     max_tries: 50
  #   )
  # end

  # defp discovery_query(uuid, message_count) do
  #   fn ->
  #     url = "#{@discovery_url}/api/v1/dataset/#{uuid}/preview"

  #     actual = url |> HTTPoison.get() |> handle_response()

  #     Logger.info("Waiting for #{message_count} messages, got #{length(actual)}")
  #     Logger.info("Messages: #{inspect(actual)}")

  #     try do
  #       assert length(actual) == message_count
  #       true
  #     rescue
  #       _ -> false
  #     end
  #   end
  # end

  # defp handle_response(response) do
  #   case response do
  #     {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
  #       body |> Jason.decode!() |> Map.get("data")

  #     {:ok, %HTTPoison.Response{status_code: status_code}} ->
  #       Logger.error("Unexpected status code from Discovery API: #{status_code}")
  #       []

  #     {:error, %HTTPoison.Error{reason: reason}} ->
  #       Logger.error("Error calling Discovery API: #{reason}")
  #       []

  #     result ->
  #       Logger.error("Unexpected result from Discovery API: #{result}")
  #   end
  # end
end

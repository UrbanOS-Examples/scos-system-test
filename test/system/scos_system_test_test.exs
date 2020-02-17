defmodule ScosSystemTest do
  use ExUnit.Case
  @moduletag timeout: 1_200_000
  alias ScosSystemTest.Helpers

  require Logger

  @temp_file_path "./tmp_file"
  # @discovery_url Application.get_env(:scos_system_test, :discovery_url)
  @default_andi_url Application.get_env(:scos_system_test, :default_andi_url)
  @default_tdg_url Application.get_env(:scos_system_test, :default_tdg_url)

  setup do
    File.rm(@temp_file_path)
    uuid = Helpers.generate_uuid()

    on_exit(fn ->
      Helpers.delete_dataset(uuid, @default_andi_url)
    end)

    [uuid: uuid]
  end

  test "adds an organization and creates a dataset for it", %{uuid: uuid} do
    record_count = 10

    Logger.info("Starting System Test with Dataset Id: #{uuid}")

    organization = Helpers.generate_organization(uuid)
    organization_id = Helpers.upload_organization(organization, @default_andi_url)

    Logger.info("Organization Id: #{organization_id}")
    Logger.info("Organization: #{inspect(organization)}")

    dataset = Helpers.generate_dataset(uuid, organization_id, record_count, @default_tdg_url)
    Logger.info("Dataset: #{inspect(dataset)}")
    %{body: body} = Helpers.upload_dataset(dataset, @default_andi_url)
    %{"technical" => %{"systemName" => system_name}} = Jason.decode!(body)
    Logger.info("Result of dataset creation: #{inspect(body)}")

    wait_for_data_to_appear_in_presto(system_name, record_count)
  end

  defp wait_for_data_to_appear_in_presto(system_name, count) do
    Patiently.wait_for!(
      presto_query(system_name, count),
      dwell: 6_000,
      max_tries: 50
    )
  end

  defp presto_query(system_name, message_count) do
    fn ->
      try do
        {:ok, %{rows: [[count]]}} =
          "select count(1) from #{system_name}__json"
          |> Helpers.execute()

        assert count == message_count
        true
      rescue
        _ ->
          false
      end
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

defmodule ScosSystemTest do
  use ExUnit.Case
  @moduletag timeout: 1_200_000

  require Logger
  import SystemLib
  alias SmartCity.TestDataGenerator, as: TDG

  @temp_file_path "./tmp_file"
  @andi_url Application.get_env(:scos_system_test, :andi_url)
  @discovery_url Application.get_env(:scos_system_test, :discovery_url)

  setup do
    File.rm(@temp_file_path)

    :ok
  end

  test "adds an organization and creates a dataset for it" do
    uuid = generate_uuid()
    record_count = 10

    Logger.info("Starting System Test with id: #{uuid}")

    organization_id =
      generate_organization(uuid)
      |> upload_organization()

    generate_raw_records(record_count)
    |> upload_data_to_bucket(uuid)

    generate_dataset(uuid, organization_id)
    |> upload_dataset()

    wait_for_data_to_appear_in_discovery(uuid, record_count)
  end

  defp generate_uuid() do
    UUID.uuid1()
    |> String.replace("-", "_")
    |> String.replace_prefix("", "SYS_")
  end

  defp generate_organization(uuid) do
    %{
      orgName: uuid <> "_ORG",
      logoUrl: Faker.Internet.image_url()
    }
    |> TDG.create_organization()
  end

  defp upload_organization(organization) do
    "#{@andi_url}/organization"
    |> HTTPoison.post!(
      organization |> Jason.encode!(),
      [{"content-type", "application/json"}]
    )
    |> Map.get(:body)
    |> Jason.decode!()
    |> Map.get("id")
  end

  defp generate_raw_records(count) do
    Enum.map(1..count, &generate_raw_record/1)
  end

  defp generate_raw_record(_) do
    [
      Faker.Name.It.name(),
      Faker.Nato.letter_code_word(),
      Faker.random_between(1, 999_999),
      Faker.random_between(1, 999) + Faker.random_between(1, 999) / 100,
      Faker.random_between(0, 1) == 1
    ]
  end

  defp upload_data_to_bucket(records, uuid) do
    records
    |> CSV.encode()
    |> write_csv(File.open!(@temp_file_path, [:append, :utf8]))

    send_to_bucket(@temp_file_path, "scos-system-test", "system-test-#{uuid}.csv")
  end

  defp write_csv(messages, io_device) do
    messages
    |> Stream.each(&IO.write(io_device, &1))
    |> Stream.run()
  end

  defp send_to_bucket(file_path, bucket, s3_key) do
    file_path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(bucket, s3_key)
    |> ExAws.request()
  end

  defp generate_dataset(uuid, organization_id) do
    %{
      id: uuid,
      technical: %{
        systemName: "scos_test__" <> uuid,
        orgId: organization_id,
        partitioner: %{
          type: "Hash",
          query: ""
        },
        cadence: "once",
        sourceType: "batch",
        sourceUrl: "https://s3.amazonaws.com/scos-system-test/system-test-#{uuid}.csv",
        sourceFormat: "csv",
        headers: %{},
        queryParams: %{},
        schema: [
          %{
            name: "name",
            type: "string"
          },
          %{
            name: "type",
            type: "string"
          },
          %{
            name: "quantity",
            type: "integer"
          },
          %{
            name: "size",
            type: "float"
          },
          %{
            name: "is_alive",
            type: "boolean"
          }
        ]
      }
    }
    |> TDG.create_dataset()
  end

  defp upload_dataset(dataset) do
    HTTPoison.put!(
      "#{@andi_url}/dataset",
      dataset |> Jason.encode!(),
      [{"content-type", "application/json"}]
    )
  end

  defp wait_for_data_to_appear_in_discovery(uuid, count) do
    Patiently.wait_for!(
      discovery_query(uuid, count),
      dwell: 10_000,
      max_tries: 60
    )
  end

  defp discovery_query(uuid, message_count) do
    fn ->
      url = "#{@discovery_url}/dataset/#{uuid}/preview"

      actual = url |> HTTPoison.get() |> handle_response()

      Logger.info("Waiting for #{message_count} messages, got #{length(actual)}")

      try do
        assert length(actual) == message_count
        true
      rescue
        _ -> false
      end
    end
  end

  defp handle_response(response) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body |> Jason.decode!() |> Map.get("data")

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.error("Discovery API not found")
        []

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Error calling Discovery API: #{reason}")
        []
    end
  end
end

defmodule ScosSystemTest do
  use ExUnit.Case
  @moduletag timeout: 1_200_000
  require Logger

  test "greets the world" do
    s3_key = System.get_env("S3_KEY")
    temp_file_path = "./tmp_file"
    File.rm(temp_file_path)

    message_count = 10

    generate_messages(message_count)
    |> CSV.encode()
    |> Stream.each(&IO.inspect/1)
    |> write_csv(File.open!(temp_file_path, [:append, :utf8]))

    uuid = UUID.uuid1() |> String.replace("-", "_")

    send_to_bucket(temp_file_path, "scos-system-test", "system-test-#{uuid}.csv")

    body = uuid |> generate_body()

    HTTPoison.put!(
      "https://andi.staging.internal.smartcolumbusos.com/api/v1/dataset",
      body,
      [{"content-type", "application/json"}]
    )

    Patiently.wait_for!(
      discovery_query(uuid, message_count),
      dwell: 10000,
      max_tries: 60
    )
  end

  defp discovery_query(uuid, message_count) do
    fn ->
      url =
        "https://discoveryapi.staging.internal.smartcolumbusos.com/api/v1/dataset/#{uuid}/preview"

      actual =
        case HTTPoison.get(url) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            body |> Jason.decode!() |> Map.get("data")

          {:ok, %HTTPoison.Response{status_code: 404}} ->
            IO.puts("Not found :(")
            []

          {:error, %HTTPoison.Error{reason: reason}} ->
            IO.inspect(reason)
            []
        end

      Logger.info("Waiting for #{length(actual)} messages, got #{message_count}")

      try do
        assert length(actual) == message_count
        true
      rescue
        _ -> false
      end
    end
  end

  def write_csv(messages, io_device) do
    messages
    |> Stream.each(&IO.write(io_device, &1))
    |> Stream.run()
  end

  def send_to_bucket(file_path, bucket, s3_key) do
    file_path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(bucket, s3_key)
    |> ExAws.request()
  end

  defp generate_messages(number) do
    [["name", "type", "quantity", "size", "is_alive"]] ++
      Enum.map(1..number, &generate_message/1)
  end

  defp generate_message(_) do
    [
      Faker.Name.It.name(),
      Faker.Nato.letter_code_word(),
      Faker.random_between(1, 999_999),
      Faker.random_between(1, 999) + Faker.random_between(1, 999) / 100,
      Faker.random_between(0, 1) == 1
    ]
  end

  defp generate_body(uuid) do
    ~s|{
      "business":{
         "contactEmail":"something@email.com",
         "contactName":"Jalson",
         "dataTitle":"System Test",
         "description":"#{uuid}",
         "license":"MIT",
         "modifiedDate":"#{DateTime.utc_now()}",
         "orgTitle":"SCOS Test"
      },
      "id":"#{uuid}",
      "technical":{
        "partitioner": {
          "type": "Hash",
          "query": "bob"
        },
         "cadence":60000,
         "dataName":"name",
         "headers":{
            "Authorization":"Basic xdasdgdasgdsgd"
         },
         "orgName":"scos-test",
         "queryParams":{

         },
         "schema":[
            {
               "name":"name",
               "type":"string"
            },
            {
               "name":"type",
               "type":"string"
            },
            {
               "name":"quantity",
               "type":"integer"
            },
            {
               "name":"size",
               "type":"float"
            },
            {
               "name":"is_alive",
               "type":"boolean"
            }
         ],
         "sourceFormat":"csv",
         "sourceUrl":"https://s3.amazonaws.com/scos-system-test/system-test-#{uuid}.csv",
         "stream":"IDK",
         "systemName":"scos__system_test_#{uuid}",
         "transformations":[
            "a_transform"
         ]
      }
   }|
  end
end

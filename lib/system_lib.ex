defmodule SystemLib do
  @moduledoc false
  require Logger

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

  def generate_messages(number) do
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

  def generate_body(uuid) do
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

  def handle_response(response) do
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

defmodule ScosSystemTest.Helpers do
  alias SmartCity.TestDataGenerator, as: TDG
  @andi_url Application.get_env(:scos_system_test, :andi_url)

  def generate_uuid() do
    UUID.uuid1()
    |> String.replace("-", "_")
    |> String.replace_prefix("", "SYS_")
  end

  def generate_organization(uuid) do
    %{
      orgName: uuid <> "_ORG",
      logoUrl: Faker.Internet.image_url()
    }
    |> TDG.create_organization()
  end

  def upload_organization(organization) do
    "#{@andi_url}/organization"
    |> HTTPoison.post!(
      organization |> Jason.encode!(),
      [{"content-type", "application/json"}]
    )
    |> Map.get(:body)
    |> Jason.decode!()
    |> Map.get("id")
  end

  def generate_dataset(uuid, organization_id, record_count) do
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
        sourceUrl: "http://data-generator.testing/api/generate",
        queryParams: %{
          "dataset_id" => uuid,
          "count" => to_string(record_count)
        },
        sourceFormat: "csv",
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
        ],
        private: false
      }
    }
    |> TDG.create_dataset()
  end

  def upload_dataset(dataset) do
    HTTPoison.put!(
      "#{@andi_url}/dataset",
      dataset |> Jason.encode!(),
      [{"content-type", "application/json"}]
    )
  end
end

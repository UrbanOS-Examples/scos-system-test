defmodule ScosSystemTest.Helpers do
  @moduledoc """
  ScosSystemTest.Helpers contains functions that are common
  between the system test and performance test,
  mostly for creating and uploading test datasets.
  """
  alias SmartCity.TestDataGenerator, as: TDG

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

  def upload_organization(organization, andi_url) do
    "#{andi_url}/api/v1/organization"
    |> HTTPoison.post!(
      organization |> Jason.encode!(),
      [{"content-type", "application/json"}]
    )
    |> Map.get(:body)
    |> Jason.decode!()
    |> Map.get("id")
  end

  def generate_dataset(uuid, organization_id, record_count, tdg_url) do
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
        sourceUrl: "#{tdg_url}/api/generate",
        sourceQueryParams: %{
          "dataset_id" => uuid,
          "count" => to_string(record_count)
        },
        sourceFormat: "csv",
        schema: [
          %{
            name: "name",
            type: "string",
            required: "true"
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

  def upload_dataset(dataset, andi_url) do
    HTTPoison.put!(
      "#{andi_url}/api/v1/dataset",
      dataset |> Jason.encode!(),
      [{"content-type", "application/json"}]
    )
  end
end

defmodule ScosSystemTest.Helpers do
  @moduledoc """
  ScosSystemTest.Helpers contains functions that are common
  between the system test and performance test,
  mostly for creating and uploading test datasets.
  """
  alias SmartCity.TestDataGenerator, as: TDG

  require Logger

  @sample_schema [
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
  ]

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
  end

  def generate_dataset(
        uuid,
        %{"id" => organization_id, "orgName" => organization_name},
        record_count,
        tdg_url,
        technical_overrides \\ %{}
      ) do
    format = Faker.Util.pick(["csv", "json"])

    %{
      id: uuid,
      technical:
        %{
          orgId: organization_id,
          orgName: organization_name,
          cadence: "once",
          sourceType: "ingest",
          extractSteps: [
            %{
              type: "http",
              assigns: %{},
              context: %{
                url: "#{tdg_url}/api/generate",
                action: "GET",
                queryParams: %{
                  "format" => format,
                  "schema" => Jason.encode!(@sample_schema),
                  "count" => to_string(record_count)
                },
                headers: %{},
                protocol: nil,
                body: %{}
              }
            }
          ],
          sourceUrl: "http://example.com",
          sourceFormat: format,
          schema: @sample_schema,
          private: false
        }
        |> Map.merge(technical_overrides)
    }
    |> TDG.create_dataset()
  end

  def upload_dataset(dataset, andi_url) do
    HTTPoison.put!(
      "#{andi_url}/api/v1/dataset",
      dataset |> Jason.encode!(),
      [{"content-type", "application/json"}]
    )
    |> Map.get(:body)
  end

  def delete_dataset(id, andi_url) do
    Logger.info("Cleaning up dataset: #{id}")

    HTTPoison.post!(
      "#{andi_url}/api/v1/dataset/delete",
      %{id: id} |> Jason.encode!(),
      [{"content-type", "application/json"}]
    )
  end

  def execute(statement) do
    try do
      Application.get_env(:prestige, :session_opts)
      |> Prestige.new_session()
      |> Prestige.execute(statement)
    rescue
      e -> e
    end
  end
end

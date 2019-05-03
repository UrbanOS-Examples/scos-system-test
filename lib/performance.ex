defmodule ScosSystemTest.Performance do
  @moduledoc """
  ScosSystemTest.Performance will eventually be an actual
  system test, but for now all it does is generate
  and upload a specified number of datasets.
  """
  require Logger
  alias ScosSystemTest.Helpers
  @default_andi_url Application.get_env(:scos_system_test, :default_andi_url)
  @default_tdg_url Application.get_env(:scos_system_test, :default_tdg_url)

  def run(options \\ []) do
    andi_url = Keyword.get(options, :andi_url, @default_andi_url)
    tdg_url = Keyword.get(options, :tdg_url, @default_tdg_url)
    record_count = Keyword.get(options, :record_count, 100)
    dataset_count = Keyword.get(options, :dataset_count, 1)
    Logger.info("Posting #{dataset_count} datasets with #{record_count} records to #{andi_url}")

    Enum.each(1..dataset_count, fn _ -> create_and_upload_dataset(andi_url, tdg_url, record_count) end)
  end

  def create_and_upload_dataset(andi_url, tdg_url, record_count) do
    uuid = Helpers.generate_uuid()

    organization = Helpers.generate_organization(uuid)
    organization_id = Helpers.upload_organization(organization, andi_url)

    dataset = Helpers.generate_dataset(uuid, organization_id, record_count, tdg_url)
    Helpers.upload_dataset(dataset, andi_url)
  end
end

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
    record_counts = Keyword.get(options, :record_counts, [100])
    record_counts_length = Enum.count(record_counts)
    dataset_count = Keyword.get(options, :dataset_count, 1)
    Logger.info("Posting #{dataset_count} datasets to #{andi_url}")

    result_list =
      Enum.map(1..dataset_count, fn i ->
        cycled_index = rem(i - 1, record_counts_length)
        cycled_record_count = Enum.at(record_counts, cycled_index)
        create_and_upload_dataset(andi_url, tdg_url, cycled_record_count)
      end)

    Logger.info("Finished posting datasets: ")

    Enum.each(result_list, fn result ->
      Logger.info("Id: #{result.id}, system name: #{result.system_name} record count: #{result.record_count}")
    end)
  end

  def create_and_upload_dataset(andi_url, tdg_url, record_count) do
    uuid = Helpers.generate_uuid()

    organization = Helpers.generate_organization(uuid)
    organization_id = Helpers.upload_organization(organization, andi_url)

    dataset = Helpers.generate_dataset(uuid, organization_id, record_count, tdg_url)
    Helpers.upload_dataset(dataset, andi_url)

    %{id: uuid, system_name: dataset.technical.systemName, record_count: record_count}
  end
end

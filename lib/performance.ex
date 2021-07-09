defmodule ScosSystemTest.Performance do
  @moduledoc """
  ScosSystemTest.Performance will eventually be an actual
  system test, but for now all it does is generate
  and upload a specified number of datasets.
  """
  require Logger
  alias ScosSystemTest.Helpers
  alias ScosSystemTest.Stats
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
      Enum.map(0..(dataset_count - 1), fn i ->
        cycled_index = rem(i, record_counts_length)
        cycled_record_count = Enum.at(record_counts, cycled_index)
        create_and_upload_dataset(andi_url, tdg_url, cycled_record_count)
      end)

    Logger.info("Finished posting datasets: ")

    Enum.each(result_list, fn result ->
      Logger.info(
        "Id: #{result.id}, system name: #{result.system_name} record count: #{result.record_count}"
      )
    end)

    result_list
  end

  def create_and_upload_dataset(andi_url, tdg_url, record_count) do
    uuid = Helpers.generate_uuid()

    organization = Helpers.generate_organization(uuid)
    organization_id = Helpers.upload_organization(organization, andi_url)

    dataset = Helpers.generate_dataset(uuid, organization_id, record_count, tdg_url)
    Helpers.upload_dataset(dataset, andi_url)

    %{technical: %{dataName: data_name}} = dataset
    org_name = organization.orgName

    %{id: uuid, system_name: "#{org_name}__#{data_name}", record_count: record_count}
  end

  def fetch_counts(datasets) do
    Enum.map(datasets, &select_count_for_dataset/1)
  end

  def fetch_stats(datasets) do
    Logger.info(fn -> "Fetching stats. This could take a few minutes." end)

    map_of_datasets = Enum.into(datasets, Map.new(), &{&1.id, &1})

    map_of_stats =
      datasets
      |> select_stats()
      |> Enum.group_by(&Map.get(&1, "dataset_id"))

    merged =
      Map.merge(map_of_datasets, map_of_stats, fn _k, dataset, stats ->
        Map.put(dataset, :stats, stats)
      end)

    Enum.map(merged, fn {_k, v} -> v end)
  end

  def aggregate_stats(datasets) do
    Enum.map(datasets, fn dataset ->
      case Map.get(dataset, :stats) do
        nil -> dataset
        stats -> Map.put(dataset, :aggregated_stats, Stats.aggregate(stats))
      end
    end)
  end

  def aggregate_by_groups(datasets, grouping_fun) do
    datasets
    |> Enum.group_by(grouping_fun)
    |> Enum.map(fn {group_key, group_of_datasets} ->
      {group_key, clean_and_aggregate_group(group_of_datasets)}
    end)
    |> Enum.into(Map.new())
  end

  def select_stats(datasets) do
    "SELECT * FROM operational_stats WHERE dataset_id IN (#{datasets_string(datasets)}) AND app='SmartCityOS' ORDER BY timestamp DESC"
    |> Helpers.execute()
  end

  defp clean_and_aggregate_group(datasets) do
    datasets
    |> Enum.map(&Map.get(&1, :stats))
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Stats.aggregate()
    |> Map.put("num_of_datasets", length(datasets))
  end

  defp select_count_for_dataset(dataset) do
    "SELECT COUNT(*) FROM #{String.downcase(dataset.system_name)}"
    |> Helpers.execute()
    |> List.flatten()
    |> List.first()
    |> log_count(dataset)
    |> (&Map.put(dataset, :inserted_count, &1)).()
  end

  def log_count(count, dataset) do
    Logger.info(fn -> "#{dataset.id}: #{count}/#{dataset.record_count}" end)

    count
  end

  defp datasets_string(datasets) do
    datasets
    |> Enum.map(fn dataset -> "'#{dataset.id}'" end)
    |> Enum.join(",")
  end
end

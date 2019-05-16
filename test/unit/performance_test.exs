defmodule ScosSystemTest.PerformanceTest do
  use ExUnit.Case
  use Placebo

  alias ScosSystemTest.Performance

  setup_all do
    datasets = [
      %{
        id: "id_1",
        record_count: 100,
        system_name: "name_1"
      },
      %{
        id: "id_2",
        record_count: 10_000,
        system_name: "name_2"
      }
    ]

    %{datasets: datasets}
  end

  test "fetch_counts adds the inserted count to each dataset", %{datasets: datasets} do
    allow Prestige.execute(any()), seq: [[[100]], [[10_000]]], meck_options: [:passthrough]

    result = Performance.fetch_counts(datasets)

    assert result == [
             %{
               id: "id_1",
               record_count: 100,
               system_name: "name_1",
               inserted_count: 100
             },
             %{
               id: "id_2",
               record_count: 10_000,
               system_name: "name_2",
               inserted_count: 10_000
             }
           ]
  end

  test "fetch_stats adds the stats to the dataset", %{datasets: datasets} do
    allow Prestige.execute(any(), any()),
      return: mock_return(["id_1", "id_2"]),
      meck_options: [:passthrough]

    results = Performance.fetch_stats(datasets)

    assert results == [
             %{
               id: "id_1",
               record_count: 100,
               system_name: "name_1",
               stats: [
                 %{
                   "app" => "_app",
                   "dataset_id" => "id_1",
                   "label" => "_label",
                   "stats" => %{
                     "average" => 0,
                     "count" => 1,
                     "max" => 0,
                     "min" => 0,
                     "std" => 0
                   },
                   "timestamp" => 5
                 }
               ]
             },
             %{
               id: "id_2",
               record_count: 10_000,
               system_name: "name_2",
               stats: [
                 %{
                   "app" => "_app",
                   "dataset_id" => "id_2",
                   "label" => "_label",
                   "stats" => %{
                     "average" => 0,
                     "count" => 1,
                     "max" => 0,
                     "min" => 0,
                     "std" => 0
                   },
                   "timestamp" => 5
                 }
               ]
             }
           ]
  end

  test "aggregate_by_groups" do
    datasets = [
      %{
        id: "id_1",
        record_count: 100,
        system_name: "name_1",
        stats: [
          %{
            "app" => "_app",
            "dataset_id" => "id_1",
            "label" => "_label",
            "stats" => %{
              "average" => 10,
              "count" => 100,
              "max" => 100,
              "min" => 1,
              "std" => 0
            },
            "timestamp" => 5
          }
        ]
      },
      %{
        id: "id_2",
        record_count: 10_000,
        system_name: "name_2",
        stats: [
          %{
            "app" => "_app",
            "dataset_id" => "id_2",
            "label" => "_label",
            "stats" => %{
              "average" => 1000.0,
              "count" => 10_000,
              "max" => 500,
              "min" => 72,
              "std" => 0
            },
            "timestamp" => 5
          }
        ]
      }
    ]

    result = Performance.aggregate_by_groups(datasets, fn x -> x.record_count end)

    assert result == %{
             100 => %{
               "average" => 10.0,
               "count" => 100,
               "max" => 100,
               "min" => 1,
               "num_of_datasets" => 1
             },
             10_000 => %{
               "average" => 1000.0,
               "count" => 10_000,
               "max" => 500,
               "min" => 72,
               "num_of_datasets" => 1
             }
           }
  end

  defp mock_return(ids) do
    Enum.map(ids, fn id ->
      %{
        "app" => "_app",
        "dataset_id" => id,
        "label" => "_label",
        "stats" => %{
          "average" => 0,
          "count" => 1,
          "max" => 0,
          "min" => 0,
          "std" => 0
        },
        "timestamp" => 5
      }
    end)
  end
end

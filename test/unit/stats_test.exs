defmodule ScosSystemTest.StatsTest do
  use ExUnit.Case

  alias ScosSystemTest.Stats

  describe "aggregate" do
    test "aggregates stats" do
      inputs = [
        stat_record(average: 5, count: 10, min: 3, max: 8, std: 2),
        stat_record(average: 3, count: 30, min: 5, max: 10, std: 2)
      ]

      assert Stats.aggregate(inputs) == %{
               "average" => 3.5,
               "count" => 40,
               "max" => 10,
               "min" => 3
             }
    end
  end

  defp stat_record(opts \\ []) do
    average = Keyword.get(opts, :average, 0)
    count = Keyword.get(opts, :count, 0)
    min_val = Keyword.get(opts, :min, 0)
    max_val = Keyword.get(opts, :max, 0)
    std = Keyword.get(opts, :std, 0)

    %{
      "app" => "Doesn't Matter",
      "dataset_id" => "some_guid",
      "label" => "some_label",
      "stats" => %{
        "average" => average,
        "count" => count,
        "max" => max_val,
        "min" => min_val,
        "std" => std
      },
      "timestamp" => 1_557_840_973
    }
  end
end

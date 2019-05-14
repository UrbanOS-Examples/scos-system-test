defmodule ScosSystemTest.Stats do
  def aggregate(stats_list) do
    stats_list
    |> Enum.map(&Map.get(&1, "stats"))
    |> Enum.reduce(%{"count" => 0, "average" => 0}, &reducer/2)
  end

  def reducer(item, acc) do
    %{
      "average" => combine_averages(item, acc),
      "min" => min(item["min"], acc["min"]),
      "max" => max(item["max"], acc["max"] || -1),
      "count" => item["count"] + acc["count"]
    }
  end

  defp combine_averages(item, acc) do
    top = item["count"] * item["average"] + acc["count"] * acc["average"]

    top / (item["count"] + acc["count"])
  end
end

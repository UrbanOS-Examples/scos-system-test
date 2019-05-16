defmodule ScosSystemTest.Stats do
  @moduledoc """
  Functions for aggregating the stats stored by Flair
  """

  @doc """
  Aggregate a list of records (as maps) returned from Flair's operational_stats table
  """
  @spec aggregate(list(map())) :: map()
  def aggregate(stats_list) do
    stats_list
    |> Enum.map(&Map.get(&1, "stats"))
    |> Enum.reduce(%{"count" => 0, "average" => 0}, &reducer/2)
  end

  defp reducer(item, acc) do
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

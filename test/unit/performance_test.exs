defmodule ScosSystemTest.PerformanceTest do
  alias ScosSystemTest.Performance
  use ExUnit.Case

  setup_all do
    %{
      "_metadata" => %{},
      "dataset_id" => "90d51c3b-8c01-4ba4-ac24-a3206458f851",
      "operational" => %{
        "timing" => [
          %{
            "app" => "voltron",
            "end_time" => "2019-05-01T15:43:30.361689Z",
            "label" => "transformations",
            "start_time" => "2019-05-01T15:43:30.361451Z"
          },
          %{
            "app" => "voltron",
            "end_time" => "2019-05-01T15:43:30.361428Z",
            "label" => "&SmartCity.Data.new/1",
            "start_time" => "2019-05-01T15:43:30.361360Z"
          },
          %{
            "app" => "valkyrie",
            "end_time" => "2019-05-01T15:43:29.854057Z",
            "label" => "timing",
            "start_time" => "2019-05-01T15:43:29.853706Z"
          },
          %{
            "app" => "reaper",
            "end_time" => "2019-05-01T15:43:29.054964Z",
            "label" => "Ingested",
            "start_time" => "2019-05-01T15:43:28.723585Z"
          }
        ],
        "transformations" => %{
          "date_times" => ["vehicle.trip.start_date"],
          "trim" => ["trip_update"]
        }
      },
      "payload" => %{},
      "version" => "0.1"
    }
  end

  # 2019-05-01T15:43:30.361428Z - 2019-05-01T15:43:28.723585Z

  test "returns difference in time from pipeline start to finish", message do
    expected = 1638104
    assert expected == Performance.calculate_end_to_end_time(message)
  end

end

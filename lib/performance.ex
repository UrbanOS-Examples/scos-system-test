defmodule ScosSystemTest.Performance do
  require Logger
  use Timex
  alias Timex.Parse.DateTime.Parser
  alias ScosSystemTest.Helpers
  def run(_environment, _dataset_count, record_count, _timeout) do
    uuid = Helpers.generate_uuid()

    Logger.info("Starting Performance Test")
    Logger.info("Dataset Id: #{uuid}")

    organization = Helpers.generate_organization(uuid)
    organization_id = Helpers.upload_organization(organization)

    Logger.info("Organization Id: #{organization_id}")
    Logger.info("Organization: #{inspect(organization)}")

    dataset = Helpers.generate_dataset(uuid, organization_id, record_count)
    Helpers.upload_dataset(dataset)
    Logger.info("Dataset: #{inspect(dataset)}")

    # wait_for_final_kafka_message(record_count, dataset_id)
  end

  def handle_message(message) do
    IO.inspect(message)
    :ok
  end

  def calculate_end_to_end_time(%{"operational" => %{"timing" => timings}}) do
    start_time = Enum.at(Enum.filter(timings, fn timing -> timing["app"] == "reaper" end), 0)["start_time"]
    end_time = Enum.at(Enum.filter(timings, fn timing -> timing["app"] == "voltron" end), 0)["end_time"]

    {:ok, start_time, 0} = DateTime.from_iso8601(start_time)
    {:ok, end_time, 0} = DateTime.from_iso8601(end_time)

    DateTime.diff(end_time, start_time, :microsecond)
  end

end

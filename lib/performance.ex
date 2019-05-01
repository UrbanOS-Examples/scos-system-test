defmodule ScosSystemTest.Performance do
  require Logger
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
  end

end

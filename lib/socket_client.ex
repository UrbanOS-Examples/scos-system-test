defmodule ScosSystemTest.SocketClient do
  @moduledoc """
  This module collects messages from Discovery Streams and stores them in an ets table
  """
  use WebSockex
  require Logger

  @max_attempts 10
  @backoff 500

  def start_link(url, state \\ %{}) do
    state = Map.put(state, :attempts, 0)

    {:ok, pid} =
      WebSockex.start_link(url, __MODULE__, state,
        extra_headers: [{"User-Agent", "scos-system-test"}]
      )

    join(pid, Map.get(state, :topic))

    :ets.new(String.to_atom(Map.get(state, :topic)), [:set, :public, :named_table])

    {:ok, pid}
  end

  def get_messages(topic) do
    :ets.tab2list(String.to_atom(topic))
  end

  defp join(pid, topic) do
    WebSockex.send_frame(pid, {:text, join_message(topic)})
  end

  defp join_message(topic),
    do: %{topic: topic, event: "phx_join", payload: %{}, ref: "1"} |> Jason.encode!()

  def handle_frame({_type, msg}, %{topic: topic, attempts: attempts} = state)
      when attempts < @max_attempts do
    payload = msg |> Jason.decode!() |> Map.get("payload")

    case payload do
      %{"status" => "error", "response" => %{"reason" => reason}} ->
        delay = attempts * @backoff

        Logger.warn(
          "Failed to connect to topic #{topic} due to '#{reason}', retrying after #{delay}ms"
        )

        Process.sleep(delay)
        {:reply, {:text, join_message(topic)}, Map.put(state, :attempts, attempts + 1)}

      %{"status" => "ok"} ->
        Logger.debug("Status message ignored")
        {:ok, state}

      payload ->
        Logger.debug("Storing message payload")
        store_message(topic, payload)
        {:ok, state}
    end
  end

  def handle_frame({_type, _msg}, %{topic: topic}) do
    Logger.error("Retries exceeded, closing connection.")
    raise "Unable to subscribe to websocket topic: #{topic}"
  end

  defp store_message(_topic, nil), do: nil

  defp store_message(topic, message) do
    :ets.insert(String.to_atom(topic), {NaiveDateTime.utc_now(), message |> Jason.encode!()})
  end
end

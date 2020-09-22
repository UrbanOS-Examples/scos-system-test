defmodule ScosSystemTest.SocketClient do
  @moduledoc """
  This module collects messages from Discovery Streams and stores them in an ets table
  """
  use WebSockex
  require Logger

  def start_link(url, state \\ %{}) do
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

  def handle_frame({_type, msg}, %{topic: topic} = state) do
    payload = msg |> Jason.decode!() |> Map.get("payload")

    case payload do
      %{"status" => "error"} ->
        Process.sleep(1000)
        Logger.debug("Unable to connect to stream, retrying")
        {:reply, {:text, join_message(topic)}, state}

      %{"status" => "ok"} ->
        Logger.debug("Status message ignored")
        {:ok, state}

      payload ->
        Logger.debug("Storing message payload")
        store_message(topic, payload)
        {:ok, state}
    end
  end

  defp store_message(_topic, nil), do: nil

  defp store_message(topic, message) do
    :ets.insert(String.to_atom(topic), {NaiveDateTime.utc_now(), message |> Jason.encode!()})
  end
end

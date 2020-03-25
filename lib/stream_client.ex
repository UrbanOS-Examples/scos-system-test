defmodule ScosSystemTest.StreamClient do
  @moduledoc false
  require Logger
  alias Phoenix.Channels.GenSocketClient
  @behaviour GenSocketClient

  @rejoin_interval_seconds 10

  def start_link(url) do
    GenSocketClient.start_link(
      __MODULE__,
      Phoenix.Channels.GenSocketClient.Transport.WebSocketClient,
      url
    )
  end

  def init(url) do
    {:connect, url, [], %{}}
  end

  def join_topic(pid, topic) do
    Process.send(pid, {:join, topic}, [])
  end

  def handle_connected(_transport, state) do
    Logger.info("connected")
    {:ok, state}
  end

  def handle_disconnected(reason, state) do
    Logger.error("disconnected: #{inspect(reason)}")
    Process.send_after(self(), :connect, :timer.seconds(@rejoin_interval_seconds))
    {:ok, state}
  end

  def handle_joined(topic, _payload, _transport, state) do
    Logger.info("joined the topic #{topic}")
    :ets.new(String.to_atom(topic), [:named_table])
    {:ok, state}
  end

  def handle_join_error(topic, payload, _transport, state) do
    Logger.warn(
      "join error on the topic #{topic}: #{inspect(payload)}\nRetrying in #{
        @rejoin_interval_seconds
      } seconds"
    )

    Process.send_after(self(), {:join, topic}, :timer.seconds(@rejoin_interval_seconds))
    {:ok, state}
  end

  def handle_channel_closed(topic, payload, _transport, state) do
    Logger.error("disconnected from the topic #{topic}: #{inspect(payload)}")
    Process.send_after(self(), {:join, topic}, :timer.seconds(@rejoin_interval_seconds))
    {:ok, state}
  end

  def handle_message(topic, event, payload, _transport, state) do
    Logger.debug("message on topic #{topic}: #{event} #{inspect(payload)}")
    :ets.insert(String.to_existing_atom(topic), {NaiveDateTime.utc_now(), payload})
    {:ok, state}
  end

  def handle_reply(topic, _ref, payload, _transport, state) do
    Logger.debug("reply on topic #{topic}: #{inspect(payload)}")
    {:ok, state}
  end

  def handle_info(:connect, _transport, state) do
    Logger.info("connecting")
    {:connect, state}
  end

  def handle_info({:join, topic}, transport, state) do
    Logger.info("joining the topic #{topic}")
    GenSocketClient.join(transport, topic)

    {:ok, state}
  end

  def handle_info(message, _transport, state) do
    Logger.warn("Unhandled message #{inspect(message)}")
    {:ok, state}
  end
end

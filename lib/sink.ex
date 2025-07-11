defmodule Membrane.SRT.Sink do
  @moduledoc """
  Membrane Sink acting as an SRT client which sends incoming data to an SRT server.
  The server listens on the specified IP address and port.
  """
  use Membrane.Sink
  require Membrane.Logger

  @max_payload_size 1316

  def_input_pad :input, accepted_format: Membrane.RemoteStream

  def_options port: [
                spec: :inet.port_number(),
                description: """
                The port number on which the SRT server listens.
                """
              ],
              ip: [
                spec: String.t(),
                default: "127.0.0.1",
                description: """
                The IP address where the SRT server is located. Defaults to 127.0.0.1 (localhost).
                """
              ],
              stream_id: [
                spec: String.t(),
                description: """
                ID of the stream being sent.
                """
              ]

  @impl true
  def handle_init(_ctx, opts) do
    {[], %{ip: opts.ip, port: opts.port, stream_id: opts.stream_id}}
  end

  @impl true
  def handle_setup(_ctx, state) do
    {:ok, client} = ExLibSRT.Client.start(state.ip, state.port, state.stream_id)
    state = Map.put(state, :client, client)
    {[setup: :incomplete], state}
  end

  @impl true
  def handle_info(:srt_client_connected, _ctx, state) do
    {[setup: :complete], state}
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    Membrane.Logger.warning("Unknown message received: #{inspect(msg)}")
    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    :ok = send_data(buffer.payload, state.client)
    {[], state}
  end

  @impl true
  def handle_end_of_stream(:input, _ctx, state) do
    :ok = ExLibSRT.Client.stop(state.client)
    {[], state}
  end

  defp send_data(<<payload::binary-size(@max_payload_size), rest::binary>>, client) do
    :ok = ExLibSRT.Client.send_data(payload, client)
    send_data(rest, client)
  end

  defp send_data(payload, client) do
    :ok = ExLibSRT.Client.send_data(payload, client)
  end
end

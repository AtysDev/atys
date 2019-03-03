defmodule Atys.Plugs.SideUnchanneler do
  alias Plug.Conn

  def init(send_after_ms: send_after_ms), do: [send_after_ms: send_after_ms]

  def init(execute: true),
    do: [execute: true, callback: &__MODULE__.default_failure_callback/1]

  def init([execute: true, callback: _callback] = opts), do: opts

  def call(%Conn{private: %{side_unchanneler_timer: _timer}}, send_after_ms: _ms) do
    raise "Tried to initialize a side unchanneler timer when one already exists"
  end

  def call(%Conn{state: state}, send_after_ms: _ms) when state != :unset do
    raise "Tried to initialize a side unchanneler after data has already been sent"
  end

  def call(%Conn{} = conn, send_after_ms: send_after_ms) do
    timer = Process.send_after(self(), :side_channeler_delay, send_after_ms)

    Conn.register_before_send(conn, &before_send_callback/1)
    |> Conn.put_private(:side_unchanneler_timer, timer)
  end

  def call(%Conn{status: nil} = conn, execute: true, callback: _callback), do: conn

  def call(%Conn{private: %{side_unchanneler_timer: timer}} = conn,
        execute: true,
        callback: callback
      )
      when timer != nil do
    case Process.read_timer(timer) do
      false ->
        clear_state(conn) |> callback.()

      _ ->
        wait_and_execute(conn)
    end
  end

  def call(%Conn{}, execute: true) do
    raise "Trying to verify the side_unchanneler timer, but send_after has not been initialized"
  end

  def before_send_callback(%Conn{private: %{side_unchanneler_timer: timer}})
      when timer != nil do
    raise "Called send_resp in a pipeline wrapped by side_unchanneler"
  end

  def before_send_callback(conn), do: conn

  def default_failure_callback(conn) do
    Conn.send_resp(
      conn,
      504,
      "The server did not complete the action within the side_unchanneler response window"
    )
  end

  defp wait_and_execute(%Conn{} = conn) do
    conn = clear_state(conn)

    receive do
      :side_channeler_delay ->
        Conn.send_resp(conn)
    after
      30_000 -> Conn.send_resp(conn, 500, "Unexpected side_unchanneler timeout")
    end
  end

  defp clear_state(conn) do
    Conn.put_private(conn, :side_unchanneler_timer, nil)
  end
end

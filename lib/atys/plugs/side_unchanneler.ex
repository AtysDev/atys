defmodule Atys.Plugs.SideUnchanneler do
  alias Plug.Conn

  def init(send_after_ms: send_after_ms), do: [send_after_ms: send_after_ms]

  def init(execute: true),
    do: [execute: true, callback: &__MODULE__.default_failure_callback/1]

  def init([execute: true, callback: _callback] = opts), do: opts

  def call(%Conn{private: %{side_unchanneler_send_at: _timer}}, send_after_ms: _ms) do
    raise "Tried to initialize a side unchanneler timer when one already exists"
  end

  def call(%Conn{state: state}, send_after_ms: _ms) when state != :unset do
    raise "Tried to initialize a side unchanneler after data has already been sent"
  end

  def call(%Conn{} = conn, send_after_ms: send_after_ms) do
    send_at = now() + send_after_ms

    Conn.register_before_send(conn, &before_send_callback/1)
    |> Conn.put_private(:side_unchanneler_send_at, send_at)
  end

  def call(%Conn{private: %{side_unchanneler_send_at: send_at}} = conn, execute: true, callback: callback) do
    clear_state(conn)
    |> delay_and_execute(%{delay: send_at - now(), callback: callback})
  end

  def call(%Conn{}, execute: true) do
    raise "Trying to verify the side_unchanneler timer, but send_after has not been initialized"
  end

  def before_send_callback(%Conn{private: %{side_unchanneler_send_at: _send_at}}) do
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

  defp delay_and_execute(%Conn{state: :set} = conn, %{delay: delay}) when delay > 0 do
    # Cowboy spins up its own process per-request
    # and therefore it's okay to block the whole process for a response
    Process.sleep(delay)
    Conn.send_resp(conn)
  end
  defp delay_and_execute(%Conn{state: :set} = conn, %{callback: callback}), do: callback.(conn)
  defp delay_and_execute(conn, _), do: conn

  defp clear_state(%Conn{} = conn) do
    pop_in(conn, [Access.key!(:private), Access.key(:side_unchanneler_send_at)])
    |> elem(1)
  end

  defp now(), do: System.monotonic_time(:millisecond)
end

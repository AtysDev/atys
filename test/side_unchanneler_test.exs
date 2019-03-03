defmodule Atys.SideUnchannelerTest do
  alias Plug.Conn
  use ExUnit.Case, async: true
  use Plug.Test

  defmodule Sleepy do
    def init(opts), do: opts

    def call(conn, amount) do
      Process.sleep(amount)
      Conn.resp(conn, 200, "hello world")
    end
  end

  test "execution finishes early, and the plug waits" do
    defmodule WorkingPipeline do
      alias Atys.Plugs.SideUnchanneler
      use Plug.Builder

      plug(SideUnchanneler, send_after_ms: 5)
      plug(Sleepy, 2)
      plug(SideUnchanneler, execute: true)
    end

    conn =
      conn(:get, "/")
      |> WorkingPipeline.call([])

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "hello world"
  end

  test "execution finishes late, and the default callback runs" do
    defmodule LatePipeline do
      alias Atys.Plugs.SideUnchanneler
      use Plug.Builder

      plug(SideUnchanneler, send_after_ms: 1)
      plug(Sleepy, 2)
      plug(SideUnchanneler, execute: true)
    end

    conn =
      conn(:get, "/")
      |> LatePipeline.call([])

    assert conn.state == :sent
    assert conn.status == 504

    assert conn.resp_body ==
             "The server did not complete the action within the side_unchanneler response window"
  end

  test "execution finishes late, and a custom callback runs" do
    defmodule LateCustomPipeline do
      alias Atys.Plugs.SideUnchanneler
      use Plug.Builder

      plug(SideUnchanneler, send_after_ms: 1)
      plug(Sleepy, 2)
      plug(SideUnchanneler, execute: true, callback: &__MODULE__.late_callback/1)

      def late_callback(conn) do
        Plug.Conn.send_resp(conn, 200, "whee")
      end
    end

    conn =
      conn(:get, "/")
      |> LateCustomPipeline.call([])

    assert conn.state == :sent
    assert conn.status == 200

    assert conn.resp_body == "whee"
  end

  test "throws if attempts to reset the send_after plug" do
    defmodule DoubleSendAfterPipeline do
      alias Atys.Plugs.SideUnchanneler
      use Plug.Builder

      plug(SideUnchanneler, send_after_ms: 5)
      plug(SideUnchanneler, send_after_ms: 5)
      plug(Sleepy, 2)
      plug(SideUnchanneler, execute: true)
    end

    assert_raise(
      RuntimeError,
      "Tried to initialize a side unchanneler timer when one already exists",
      fn ->
        DoubleSendAfterPipeline.call(conn(:get, "/"), [])
      end
    )
  end

  test "throws if attempt to set up a side unchanneler after a send_resp" do
    defmodule AlreadySentPipeline do
      alias Atys.Plugs.SideUnchanneler
      use Plug.Builder

      plug(Sleepy, 2)
      plug(SideUnchanneler, send_after_ms: 5)
      plug(SideUnchanneler, execute: true)
    end

    assert_raise(
      RuntimeError,
      "Tried to initialize a side unchanneler after data has already been sent",
      fn ->
        AlreadySentPipeline.call(conn(:get, "/"), [])
      end
    )
  end

  test "throws if send_resp is used" do
    defmodule BadSendResponse do
      alias Atys.Plugs.SideUnchanneler
      use Plug.Builder
      alias Plug.Conn

      plug(SideUnchanneler, send_after_ms: 5)
      plug(:send_resp)
      plug(SideUnchanneler, execute: true)

      def send_resp(conn, _opts), do: Conn.send_resp(conn, 200, "oops")
    end

    assert_raise(RuntimeError, "Called send_resp in a pipeline wrapped by side_unchanneler", fn ->
      BadSendResponse.call(conn(:get, "/"), [])
    end)
  end

  test "does nothing if send_resp wasn't called" do
    defmodule NoSendResponse do
      alias Atys.Plugs.SideUnchanneler
      use Plug.Builder
      plug(SideUnchanneler, send_after_ms: 5)
      plug(SideUnchanneler, execute: true)
    end

    conn = NoSendResponse.call(conn(:get, "/"), [])
    assert conn.state == :unset
  end
end

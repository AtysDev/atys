defmodule StaticWebserverTest do
  alias Atys.Plugs.StaticWebserver
  use ExUnit.Case, async: true
  use Plug.Test

  setup do
    key = Base.url_encode64(<<1::256>>)
    {:ok, pid} = start_supervised({Atys.StaticKeyStore, key})
    opts = StaticWebserver.init(server_name: pid)

    %{
      key: key,
      store_pid: pid,
      opts: opts
    }
  end

  test "returns 404", context do
    conn =
      conn(:get, "/missing")
      |> StaticWebserver.call(context[:opts])

    assert conn.state == :sent
    assert conn.status == 404
  end

  test "404 when the method is POST", context do
    conn =
      conn(:post, "/encrypt")
      |> StaticWebserver.call(context[:opts])

    assert conn.state == :sent
    assert conn.status == 404
  end

  test "encrypt returns 400 when the param is missing", context do
    conn =
      conn(:get, "/encrypt")
      |> StaticWebserver.call(context[:opts])

    assert conn.state == :sent
    assert conn.status == 400
  end

  test "encrypt returns 200 when passed a value", context do
    conn =
      conn(:get, "/encrypt?v=hello%20world")
      |> StaticWebserver.call(context[:opts])

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "decrypt returns 200", context do
    encrypted =
      "eyJhbGciOiJkaXIiLCJlbmMiOiJBMjU2R0NNIn0..q2xdybd8ywZvUcbg.aeAn6qB_pnV6A0A.MSC4_MSRysYismaIp-1ZhQ"

    conn =
      conn(:get, "/decrypt?v=#{encrypted}")
      |> StaticWebserver.call(context[:opts])

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "hello world"
  end

  test "decrypt returns 500 when the wrong key is used", context do
    encrypted =
      "eyJhbGciOiJkaXIiLCJlbmMiOiJBMjU2R0NNIn0..h32S2S4kD94ArdLJ.EQcICaat4-YteT8.WASSyJw1A84djA5QkXwyRw"

    conn =
      conn(:get, "/decrypt?v=#{encrypted}")
      |> StaticWebserver.call(context[:opts])

    assert conn.state == :sent
    assert conn.status == 400
  end
end

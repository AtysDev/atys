defmodule StaticWebserverTest do
  alias Atys.Plugs.StaticWebserver
  alias Atys.Crypto.Message
  use ExUnit.Case, async: true
  use Plug.Test

  defmodule DummyCryptographer do
    alias Atys.Behaviours.StaticCryptographer
    @behaviour StaticCryptographer

    @impl StaticCryptographer
    def encrypt_256(_context, plaintext) do
      {:ok, "aoeu" <> plaintext}
    end

    @impl StaticCryptographer
    def decrypt_256(_context, "asdf" <> _ciphertext) do
      {:error, :invalid_decryption_key}
    end

    @impl StaticCryptographer
    def decrypt_256(_context, "aoeu" <> plaintext) do
      {:ok, plaintext}
    end
  end

  @opts [cryptographer: {DummyCryptographer, nil}]

  test "returns 404" do
    conn =
      conn(:get, "/missing")
      |> StaticWebserver.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end

  test "400 when trying to encrypt something larger than the max # of bytes" do
    assert_raise(Plug.Conn.InvalidQueryError, fn ->
      text = String.duplicate("a", 11_000)

      conn(:get, "/encrypt?v=#{text}")
      |> StaticWebserver.call(@opts)
    end)
  end

  test "404 when the method is POST" do
    conn =
      conn(:post, "/encrypt")
      |> StaticWebserver.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end

  test "encrypt returns 400 when the param is missing" do
    conn =
      conn(:get, "/encrypt")
      |> StaticWebserver.call(@opts)

    assert conn.state == :sent
    assert conn.status == 400
  end

  test "encrypt returns 200 when passed a value" do
    conn =
      conn(:get, "/encrypt?v=hello%20world")
      |> StaticWebserver.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert "aoeu"<> body = conn.resp_body
    assert %{"p" => "hello world"} = Jason.decode!(body)
  end

  test "decrypt returns 200" do
    encrypted = "aoeu" <> Message.serialize!(%Message{plaintext: "hello world"})

    conn =
      conn(:get, "/decrypt?v=#{encrypted}")
      |> StaticWebserver.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "hello world"
  end

  test "decrypt returns 400 when the content blob is not a message" do
    encrypted = "aoeuhelloworld"

    conn =
      conn(:get, "/decrypt?v=#{encrypted}")
      |> StaticWebserver.call(@opts)

    assert conn.state == :sent
    assert conn.status == 400
  end

  test "decrypt returns 400 when the wrong key is used" do
    conn =
      conn(:get, "/decrypt?v=asdfbad key")
      |> StaticWebserver.call(@opts)

    assert conn.state == :sent
    assert conn.status == 400
  end
end

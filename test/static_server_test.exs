defmodule StaticServerTest do
  alias Atys.StaticServer
  use ExUnit.Case, async: true

  @key Base.url_encode64(<<1::256>>)

  test "fails if the encryption key is not valid" do
    assert {:error, :cannot_decode_key} =
             Task.async(fn ->
               Process.flag(:trap_exit, true)
               StaticServer.start_link("wrong key")
             end)
             |> Task.await()
  end

  test "Encrypt a value" do
    {:ok, pid} = start_supervised({StaticServer, @key})
    assert {:ok, ciphertext} = StaticServer.encrypt(pid, "hello")
  end

  test "Decrypts a value" do
    {:ok, ciphertext} = Atys.Crypto.AES.encrypt_256(@key, "hello")
    {:ok, pid} = start_supervised({StaticServer, @key})
    assert {:ok, "hello"} = StaticServer.decrypt(pid, ciphertext)
  end
end

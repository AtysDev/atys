defmodule StaticKeyStoreTest do
  alias Atys.StaticKeyStore
  use ExUnit.Case, async: true

  @key Base.url_encode64(<<1::256>>)

  test "fails if the encryption key is not valid" do
    assert {:error, :cannot_decode_key} =
             Task.async(fn ->
               Process.flag(:trap_exit, true)
               StaticKeyStore.start_link("wrong key")
             end)
             |> Task.await()
  end

  test "Encrypt a value" do
    {:ok, pid} = start_supervised({StaticKeyStore, @key})
    assert {:ok, ciphertext} = StaticKeyStore.encrypt(pid, "hello")
  end

  test "Decrypts a value" do
    {:ok, ciphertext} = Atys.Crypto.AES.encrypt_256(@key, "hello")
    {:ok, pid} = start_supervised({StaticKeyStore, @key})
    assert {:ok, "hello"} = StaticKeyStore.decrypt(pid, ciphertext)
  end
end

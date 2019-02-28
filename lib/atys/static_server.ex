defmodule Atys.StaticServer do
  alias Atys.Crypto.AES
  use GenServer

  def start_link(encryption_key, opts \\ []) do
    GenServer.start_link(__MODULE__, encryption_key, opts)
  end

  def encrypt(pid, plaintext) do
    GenServer.call(pid, {:encrypt, plaintext})
  end

  def decrypt(pid, ciphertext) do
    GenServer.call(pid, {:decrypt, ciphertext})
  end

  @impl true
  def init(encryption_key) do
    case AES.get_jwk(encryption_key) do
      {:ok, jwk} -> {:ok, %{jwk: jwk}}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call({:encrypt, plaintext}, _from, %{jwk: jwk} = state) do
    {:reply, AES.encrypt_256(jwk, plaintext), state}
  end

  @impl true
  def handle_call({:decrypt, ciphertext}, _from, %{jwk: jwk} = state) do
    {:reply, AES.decrypt_256(jwk, ciphertext), state}
  end
end

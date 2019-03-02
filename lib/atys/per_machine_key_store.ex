defmodule Atys.PerMachineKeyStore do
  alias Atys.Crypto.AES
  alias Atys.Behaviours.PerMachineCryptographer
  use GenServer
  @behaviour PerMachineCryptographer

  def start_link(key_value_store_info, opts \\ []) do
    GenServer.start_link(__MODULE__, key_value_store_info, opts)
  end

  @impl PerMachineCryptographer
  def encrypt_256(pid, data) do
    GenServer.call(
      pid,
      {:encrypt, data}
    )
  end

  @impl PerMachineCryptographer
  def decrypt_256(pid, data) do
    GenServer.call(
      pid,
      {:decrypt, data}
    )
  end

  @impl true
  def init({key_value_store_module, key_value_store_context}) do
    {:ok,
     %{
       store_module: key_value_store_module,
       store_context: key_value_store_context
     }}
  end

  @impl true
  def handle_call(
        {action, %{machine_id: machine_id, machine_key: machine_key, contents: contents}},
        _from,
        state
      ) do
    with {:ok, encryption_key} <-
           get_encryption_key(state: state, machine_id: machine_id, machine_key: machine_key),
         {:ok, result} <- perform_action(action, encryption_key, contents) do
      {:reply, {:ok, result}, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  defp get_encryption_key(state: state, machine_id: machine_id, machine_key: machine_key) do
    with {:ok, encrypted_encryption_key} <- get_value(state, machine_id),
         {:ok, encryption_key} <- AES.decrypt_256(machine_key, encrypted_encryption_key) do
      {:ok, encryption_key}
    else
      {:error, :invalid_decryption_key} -> {:error, :invalid_machine_key}
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_value(%{store_module: store_module, store_context: store_context}, key) do
    store_module.get(store_context, key)
  end

  defp perform_action(:encrypt, encryption_key, plaintext),
    do: AES.encrypt_256(encryption_key, plaintext)

  defp perform_action(:decrypt, encryption_key, ciphertext),
    do: AES.decrypt_256(encryption_key, ciphertext)
end

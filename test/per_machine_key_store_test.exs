defmodule Atys.PerMachineKeyStoreTest do
  alias Atys.Crypto.AES
  alias Atys.PerMachineKeyStore
  use ExUnit.Case, async: true

  @machine_key_1 Base.url_encode64(<<0::256>>)
  @machine_key_2 Base.url_encode64(<<1::256>>)

  @encryption_key_1 Base.url_encode64(<<2::256>>)
  @encryption_key_2 Base.url_encode64(<<3::256>>)

  @ciphertext_1 AES.encrypt_256(@encryption_key_1, "hello") |> elem(1)
  @ciphertext_2 AES.encrypt_256(@encryption_key_2, "hello") |> elem(1)

  defmodule DummyKeyStore do
    @behaviour Atys.Behaviours.KeyValueStore
    @impl true

    @machine_key_1 Base.url_encode64(<<0::256>>)
    @machine_key_2 Base.url_encode64(<<1::256>>)

    @encryption_key_1 Base.url_encode64(<<2::256>>)
    @encryption_key_2 Base.url_encode64(<<3::256>>)

    @store %{
      "1" => AES.encrypt_256(@machine_key_1, @encryption_key_1) |> elem(1),
      "2" => AES.encrypt_256(@machine_key_2, @encryption_key_2) |> elem(1)
    }

    def get(_context, key) do
      case Map.fetch(@store, key) do
        {:ok, value} -> {:ok, value}
        :error -> {:error, :missing_id}
      end
    end

    @impl true
    def put(_context, _key, _value), do: {:error, :not_implemented}
  end

  setup do
    pid = start_supervised!({Atys.PerMachineKeyStore, {DummyKeyStore, nil}})
    %{pid: pid}
  end

  describe "Encrypt" do
    test "returns :missing_id if the machine id is not found", %{pid: pid} do
      assert {:error, :missing_id} =
               PerMachineKeyStore.encrypt_256(pid, %{
                 machine_id: "wrong",
                 machine_key: @machine_key_1,
                 contents: "hello"
               })
    end

    test "returns invalid_machine_key if the machine key doesn't match the machine id", %{
      pid: pid
    } do
      assert {:error, :invalid_machine_key} =
               PerMachineKeyStore.encrypt_256(pid, %{
                 machine_id: "1",
                 machine_key: @machine_key_2,
                 contents: "hello"
               })
    end

    test "successfully using the machine id & key", %{pid: pid} do
      assert {:ok, ciphertext} =
               PerMachineKeyStore.encrypt_256(pid, %{
                 machine_id: "1",
                 machine_key: @machine_key_1,
                 contents: "hello"
               })

      assert {:ok, "hello"} = AES.decrypt_256(@encryption_key_1, ciphertext)
    end
  end

  describe "Decrypt" do
    test "returns :missing_id if the machine id is not found", %{pid: pid} do
      assert {:error, :missing_id} =
               PerMachineKeyStore.decrypt_256(pid, %{
                 machine_id: "wrong",
                 machine_key: @machine_key_1,
                 contents: @ciphertext_1
               })
    end

    test "returns invalid_machine_key if the machine key doesn't match the machine id", %{
      pid: pid
    } do
      assert {:error, :invalid_machine_key} =
               PerMachineKeyStore.decrypt_256(pid, %{
                 machine_id: "1",
                 machine_key: @machine_key_2,
                 contents: @ciphertext_1
               })
    end

    test "returns invalid_decryption_key if the contents don't match the decryption key", %{
      pid: pid
    } do
      assert {:error, :invalid_decryption_key} =
               PerMachineKeyStore.decrypt_256(pid, %{
                 machine_id: "1",
                 machine_key: @machine_key_1,
                 contents: @ciphertext_2
               })
    end

    test "successfully using the machine id & key", %{pid: pid} do
      assert {:ok, "hello"} =
               PerMachineKeyStore.decrypt_256(pid, %{
                 machine_id: "1",
                 machine_key: @machine_key_1,
                 contents: @ciphertext_1
               })
    end
  end
end

defmodule AesTest do
  alias JOSE.{JWK, JWE}
  alias Atys.Crypto.AES
  use ExUnit.Case, async: true

  @key Base.url_encode64(<<1::256>>)
  @wrong_key Base.url_encode64(<<0::256>>)

  setup_all do
    {:ok, ciphertext} = AES.encrypt_256(@key, "hello")

    %{ciphertext: ciphertext}
  end

  describe "GCM 256 Encryption tests" do
    test "Errors if the key is not base64 encoded" do
      assert {:error, :cannot_decode_key} = AES.encrypt_256("not!@b64encoded", "hello")
    end

    test "Errors if the key is not 256 bits" do
      key = <<1::128>>
      assert 128 = bit_size(key)

      assert {:error, :invalid_key_length} =
               key
               |> Base.url_encode64()
               |> AES.encrypt_256("hello")
    end

    test "Successfully encrypts a string" do
      assert {:ok, ciphertext} = AES.encrypt_256(@key, "hello")

      assert "hello" =
               Atys.Crypto.decode_key(@key)
               |> elem(1)
               |> JWK.from_oct()
               |> JWE.block_decrypt(ciphertext)
               |> elem(0)
    end
  end

  describe "GCM 256 Decryption tests" do
    test "Errors if the encryption method isn't GCM256", %{ciphertext: ciphertext} do
      header = "{\"alg\":\"dir\",\"enc\":\"A128GCM\"}" |> Base.url_encode64(padding: false)

      [_header | tail] = String.split(ciphertext, ".")
      ciphertext = Enum.join([header | tail], ".")

      assert {:error, :encryption_method_error} = AES.decrypt_256(@key, ciphertext)
    end

    test "Errors if the key is not base64 encoded", %{ciphertext: ciphertext} do
      assert {:error, :cannot_decode_key} = AES.decrypt_256("not!@b64encoded", ciphertext)
    end

    test "Errors if the key is not 256 bits", %{ciphertext: ciphertext} do
      key = <<1::128>>
      assert 128 = bit_size(key)

      assert {:error, :invalid_key_length} =
               key
               |> Base.url_encode64()
               |> AES.decrypt_256(ciphertext)
    end

    test "Errors if using the wrong key", %{ciphertext: ciphertext} do
      assert {:error, :invalid_decryption_key} = AES.decrypt_256(@wrong_key, ciphertext)
    end

    test "Decrypts the key correctly", %{ciphertext: ciphertext} do
      assert {:ok, "hello"} = AES.decrypt_256(@key, ciphertext)
    end
  end
end

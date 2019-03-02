defmodule Atys.Crypto.AES do
  alias JOSE.{JWK, JWE}
  @alg_signature %{alg: :jose_jwe_alg_dir, enc: :jose_jwe_enc_aes}

  @jwe_256_binary "{\"alg\":\"dir\",\"enc\":\"A256GCM\"}"
  @jwe_256 JWE.from_binary(@jwe_256_binary)
  @jwe_256_signature Base.url_encode64(@jwe_256_binary, padding: false)

  def encrypt_256(%JWK{} = jwk, plaintext) when is_binary(plaintext) do
    with {:ok, cipher} <- block_encrypt_256(jwk, plaintext),
         :ok <- validate_ciphertext_algorithm(cipher) do
      {:ok, cipher}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :unknown_failure}
    end
  end

  def encrypt_256(<<encoded_key::binary>>, plaintext) do
    case get_jwk(encoded_key) do
      {:ok, jwk} -> encrypt_256(jwk, plaintext)
      error -> error
    end
  end

  def decrypt_256(%JWK{} = jwk, ciphertext) when is_binary(ciphertext) do
    with :ok <- validate_ciphertext_algorithm(ciphertext),
         {:ok, plaintext} <- block_decrypt_256(jwk, ciphertext) do
      {:ok, plaintext}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :unknown_failure}
    end
  end

  def decrypt_256(<<encoded_key::binary>>, ciphertext) do
    case get_jwk(encoded_key) do
      {:ok, jwk} -> decrypt_256(jwk, ciphertext)
      error -> error
    end
  end

  def get_jwk(encoded_key) do
    with {:ok, key} <- Atys.Crypto.decode_key(encoded_key),
         :ok <- validate_key(key) do
      {:ok, JWK.from_oct(key)}
    else
      error -> error
    end
  end

  defp validate_key(<<_rest::size(256)>>), do: :ok

  defp validate_key(_key), do: {:error, :invalid_key_length}

  defp block_encrypt_256(jwk, plaintext) do
    case JWE.block_encrypt(jwk, plaintext, @jwe_256) do
      {@alg_signature, jwe} ->
        {%{}, cipher} = JWE.compact(jwe)
        {:ok, cipher}

      _ ->
        {:error, :encryption_method_error}
    end
  end

  defp block_decrypt_256(jwk, ciphertext) do
    case JWE.block_decrypt(jwk, ciphertext) do
      {:error, @jwe_256} -> {:error, :invalid_decryption_key}
      {:error, _} -> {:error, :encryption_method_error}
      {plaintext, @jwe_256} -> {:ok, plaintext}
      _ -> {:error, :unknown_failure}
    end
  end

  defp validate_ciphertext_algorithm(ciphertext = @jwe_256_signature <> "." <> <<_rest::binary>>) do
    {%{}, jwe} = JWE.expand(ciphertext)

    case jwe["protected"] do
      @jwe_256_signature -> :ok
      _ -> {:error, :encryption_method_error}
    end
  end

  defp validate_ciphertext_algorithm(_key), do: {:error, :encryption_method_error}
end

defmodule Atys.Behaviours.StaticCryptographer do
  @type plaintext :: String.t()
  @type ciphertext :: String.t()
  @type context :: term

  @callback encrypt_256(context, plaintext) :: {:ok, ciphertext} | {:error, term}
  @callback decrypt_256(context, ciphertext) :: {:ok, plaintext} | {:error, term}
end

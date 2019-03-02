defmodule Atys.Behaviours.PerMachineCryptographer do
  @type plaintext :: String.t()
  @type ciphertext :: String.t()
  @type context :: term
  @type t :: %{
          machine_id: String.t(),
          machine_key: String.t(),
          contents: plaintext
        }

  @callback encrypt_256(context, t) :: {:ok, ciphertext} | {:error, term}

  @callback decrypt_256(context, t) :: {:ok, plaintext} | {:error, term}
end

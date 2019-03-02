defmodule Atys.Behaviours.StaticCryptographer do
  @callback encrypt_256(term, String.t()) :: {:ok, String.t()} | {:error, term}
  @callback decrypt_256(term, String.t()) :: {:ok, String.t()} | {:error, term}
end

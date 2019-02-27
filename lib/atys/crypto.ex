defmodule Atys.Crypto do
  def encode_key(key), do: Base.url_encode64(key)

  def decode_key(key) do
    case Base.url_decode64(key) do
      {:ok, decoded} -> {:ok, decoded}
      :error -> {:error, :cannot_decode_key}
    end
  end
end

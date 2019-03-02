defmodule Atys.CryptoTest do
  alias Atys.Crypto
  use ExUnit.Case, async: true

  test "decode_key returns {:error, :cannot_decode_key} if not properly encoded" do
    assert {:error, :cannot_decode_key} = Crypto.decode_key("not*!validurlb64")
  end

  test "decode_key returns {:ok, decoded} when encoded properly" do
    key = "hello" |> Base.url_encode64()
    assert {:ok, "hello"} = Crypto.decode_key(key)
  end
end

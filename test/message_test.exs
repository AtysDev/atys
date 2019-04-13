defmodule Atys.MessageTest do
  alias Atys.Crypto.Message
  use ExUnit.Case, async: true

  test "serializes a Message struct" do
    assert {:ok, "{\"c\":null,\"i\":null,\"m\":0,\"p\":null,\"v\":1,\"x\":null}"} == Message.serialize(%Message{})
  end

  test "serializes a Message struct with a mode and cipher" do
    assert {:ok, "{\"c\":null,\"i\":null,\"m\":22,\"p\":\"hello\",\"v\":1,\"x\":null}"} ==
             Message.serialize(%Message{plaintext: "hello", mode: 22})
  end

  test "decodes a Message struct" do
    assert {:ok, %Message{plaintext: "hello", mode: 22, version: 1}} ==
             Message.deserialize("{\"p\":\"hello\",\"m\":22,\"v\":1}")
  end

  test "ignores invalid fields" do
    assert {:ok, %Message{plaintext: "hello", mode: 22, version: 1}} ==
             Message.deserialize("{\"p\":\"hello\",\"m\":22,\"v\":1,\"foo\": 2}")
  end
end

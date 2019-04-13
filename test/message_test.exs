defmodule Atys.MessageTest do
  alias Atys.Crypto.Message
  use ExUnit.Case, async: true

  test "serializes a Message struct with a mode and cipher" do
    assert {:ok, "{\"c\":null,\"i\":null,\"j\":1,\"m\":22,\"p\":\"hello\",\"v\":1,\"x\":null}"} ==
             Message.serialize(%Message{plaintext: "hello", project_id: 1, mode: 22})
  end

  test "decodes a Message struct" do
    assert {:ok, %Message{plaintext: "hello", project_id: 1, mode: 22, version: 1}} ==
             Message.deserialize("{\"p\":\"hello\",\"m\":22,\"v\":1,\"j\":1}")
  end

  test "ignores invalid fields" do
    assert {:ok, %Message{plaintext: "hello", project_id: 1, mode: 22, version: 1}} ==
             Message.deserialize("{\"p\":\"hello\",\"m\":22,\"v\":1,\"foo\":2,\"j\":1}")
  end
end

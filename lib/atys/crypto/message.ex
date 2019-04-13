defmodule Atys.Crypto.Message do
  @fields %{
    plaintext: {"p", nil},
    project_id: {"j", nil},
    version: {"v", 1},
    mode: {"m", 0},
    id: {"i", nil},
    parity: {"x", nil},
    csv: {"c", nil}
  }
  @struct_definition Enum.map(@fields, fn {k, {_shorthand, default}} -> {k, default} end)
  @shorthand_keys Enum.map(@fields, fn {_k, {shorthand, _default}} -> shorthand end)

  @enforce_keys [:plaintext, :project_id]
  defstruct @struct_definition

  def serialize(%Atys.Crypto.Message{} = data) do
    for(
      {k, v} <- Map.from_struct(data),
      into: %{},
      do: {to_shorthand(k), v}
    )
    |> Jason.encode()
  end

  def serialize!(%Atys.Crypto.Message{} = data) do
    case serialize(data) do
      {:ok, serialized} -> serialized
      {:error, error} -> raise error
    end
  end

  def deserialize(serialized) do
    case decode(serialized) do
      {:ok, decoded} ->
        data = for {k, v} <- filter_valid_keys(decoded), into: %{}, do: {from_shorthand(k), v}
        {:ok, struct(__MODULE__, data)}

      {:error, _error} ->
        {:error, :invalid_message_json}
    end
  end

  defp to_shorthand(key), do: @fields[key] |> elem(0)

  defp from_shorthand(key) do
    Enum.find(@fields, fn {_key, {shorthand, _default}} -> key == shorthand end)
    |> elem(0)
  end

  defp decode(data) do
    case Jason.decode(data) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, _error} -> {:error, :json_decode_error}
    end
  end

  defp filter_valid_keys(decoded) do
    Enum.filter(decoded, fn {k, _v} -> Enum.member?(@shorthand_keys, k) end)
  end
end

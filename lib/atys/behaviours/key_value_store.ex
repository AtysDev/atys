defmodule Atys.Behaviours.KeyValueStore do
  @type key :: String.t()
  @type value :: String.t()
  @type context :: term

  @callback get(context, key) :: {:ok, value} | {:error, term}
  @callback put(context, key, value) :: :ok | {:error, term}
end

defmodule Atys.Plugs.StaticWebserver do
  alias Plug.Conn

  def init(options) do
    {_module, _context} = Keyword.fetch!(options, :cryptographer)
    options
  end

  def call(%Conn{path_info: ["encrypt"], method: "GET"} = conn, opts),
    do: handle(:encrypt, conn, opts)

  def call(%Conn{path_info: ["decrypt"], method: "GET"} = conn, opts),
    do: handle(:decrypt, conn, opts)

  def call(conn, _opts), do: Conn.send_resp(conn, 404, "Unknown resource")

  defp handle(action, conn, opts) do
    with conn <- Conn.fetch_query_params(conn),
         {:ok, value} <- get_value(conn),
         {:ok, response} <- get_response(action, opts[:cryptographer], value) do
      Conn.send_resp(conn, 200, response)
    else
      error -> send_error(conn, opts, error)
    end
  end

  defp send_error(conn, _opts, {:error, :missing_value}),
    do: Conn.send_resp(conn, 400, "Missing the v? query param")

  defp send_error(conn, _opts, {:error, :invalid_decryption_key}),
    do: Conn.send_resp(conn, 400, "Cannot decrypt, wrong encryption key")

  defp send_error(conn, opts, {:error, reason}) do
    case Keyword.fetch(opts, :verbose) do
      {:ok, true} -> Conn.send_resp(conn, 500, "[VERBOSE] Failed with error #{reason}")
      _ -> Conn.send_resp(conn, 500, "Unknown failure")
    end
  end

  defp get_value(%{query_params: %{"v" => value}}), do: {:ok, value}
  defp get_value(_conn), do: {:error, :missing_value}

  defp get_response(:encrypt, {cryptographer_module, context}, plaintext) do
    cryptographer_module.encrypt_256(context, plaintext)
  end

  defp get_response(:decrypt, {cryptographer_module, context}, ciphertext) do
    cryptographer_module.decrypt_256(context, ciphertext)
  end
end

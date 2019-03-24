# Atys

## Side Unchanneler
This plugin prevents side attacks by delaying every request (successful or otherwise) for a specific amount of time.

It's used in a plug pipeline in a fashion similar to the following usage:

```elixir
defmodule WorkingPipeline do
  alias Atys.Plugs.SideUnchanneler
  use Plug.Builder

  plug(SideUnchanneler, send_after_ms: 5)
  plug :route
  plug(SideUnchanneler, execute: true, callback: &__MODULE__.late_callback/1)

  def late_callback(conn) do
    Plug.Conn.send_resp(conn, 500, "This response took too long")
  end
end
```

The requirements are:

1. Add the `plug(SideUnchanneler, send_after_ms: 5)` call high in your plug chain, as the timer will start at this point
2. In your main plug path, DO NOT call `Conn.send_resp()`. If you do, SideUnchanneler will throw an error. Instead, call `Conn.resp` which puts the response & status code but doesn't send it yet.
3. At the bottom of your plug stack, call `plug(SideUnchanneler, execute: true)`. This will call `Conn.send_resp/1` with your previously stored data
4. (Optional): You can also pass a `callback` param to do your own error handling if your plug pipeline took longer than send_after_ms

This causes one of two things to happen. After 5ms, the route command will send a response, OR, it will send a 500 if it took too long to calculate the response.

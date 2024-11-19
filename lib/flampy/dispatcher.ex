defmodule Flampy.Dispatcher do
  use Plug.Router, copy_opts_to_assign: :dispatcher

  plug :match
  plug :dispatch

  match _, via: :post do
    case get_in(conn.assigns, [:dispatcher, :routes, conn.request_path]) do
      nil ->
        send_resp(conn, 404, "oops")

      %{script: script, function: function, pool: pool} ->
        response =
          FLAME.call(pool, fn ->
            try do
              path = conn.assigns.dispatcher[:python_path]
              {:ok, pid} = :python.start([{:python_path, path}, {:python, ~c"python3"}])
              {:ok, :python.call(pid, script, function, [])}
            rescue
              error in ErlangError ->
                {:error, error.original}

              error ->
                {:error, error}
            end
          end)

        case response do
          {:ok, result} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{"result" => result}))

          {:error, {:python, class, argument, stacktrace}} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              500,
              Jason.encode!(%{
                "type" => "python",
                "message" => List.to_string(argument),
                "class" => class,
                "stacktrace" => IO.iodata_to_binary(stacktrace)
              })
            )

          {:error, error} when is_exception(error) ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              500,
              Jason.encode!(%{"type" => "elixir", "message" => Exception.message(error)})
            )

          {:error, _error} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              500,
              Jason.encode!(%{
                "type" => "unknown",
                "message" => "Unexpected error during execution"
              })
            )
        end
    end
  end
end

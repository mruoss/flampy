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
              path = :code.root_dir() |> Path.join("python") |> String.to_charlist()
              {:ok, pid} = :python.start([{:python_path, path}, {:python, ~c"python3"}])
              {:ok, :python.call(pid, script, function, [])}
            rescue
              error -> {:error, error}
            end
          end)

        case response do
          {:ok, result} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{"result" => result}))

          {:error, error} when is_exception(error) ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(500, Jason.encode!(%{"error" => Exception.message(error)}))

          {:error, error} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(500, Jason.encode!(%{"error" => "Unexpected error during execution"}))
        end
    end
  end
end

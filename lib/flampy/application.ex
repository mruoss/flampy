defmodule Flampy.Application do
  use Application

  def start(_type, [env]) do
    {flame_pools, routes} = parse_jobs(env)
    children = [{Bandit, plug: {Flampy.Dispatcher, routes: routes}} | flame_pools]

    opts = [strategy: :one_for_one, name: Flampy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp parse_jobs(env) do
    backend = if env == :prod, do: FLAMEK8sBackend, else: FLAME.LocalBackend

    jobs_file =
      :code.priv_dir(:flampy)
      |> Path.join("jobs.yaml")
      |> YamlElixir.read_from_file!()

    for job <- jobs_file["jobs"], reduce: {[], %{}} do
      {flame_pools, routes} ->
        pool_name = String.to_atom(job["name"])

        pool =
          {FLAME.Pool,
           name: pool_name,
           backend: backend,
           min: 0,
           max: 10,
           max_concurrency: 5,
           idle_shutdown_after: 30_000,
           log: :debug}

        route = %{
          script: String.to_atom(job["script"]),
          function: String.to_atom(job["function"]),
          pool: pool_name
        }

        {[pool | flame_pools], Map.put(routes, job["path"], route)}
    end
  end
end

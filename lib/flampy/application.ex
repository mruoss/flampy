defmodule Flampy.Application do
  use Application

  def start(_type, [env]) do
    jobs_file =
      :code.root_dir()
      |> Path.join("jobs.yaml")
      |> YamlElixir.read_from_file!(merge_anchors: true)

    flame_pools = parse_pools(jobs_file, env)
    routes = parse_jobs(jobs_file)
    children = [{Bandit, plug: {Flampy.Dispatcher, routes: routes}} | flame_pools]

    opts = [strategy: :one_for_one, name: Flampy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp parse_pools(jobs_file, env) do
    base_opts = [
      min: 0,
      max: 10,
      max_concurrency: 5,
      idle_shutdown_after: 30_000,
      log: :debug
    ]

    for pool <- jobs_file["pools"] do
      pool_name = String.to_atom(pool["name"])

      pool_opts =
        if env == :prod do
          [
            name: pool_name,
            backend: {FLAMEK8sBackend, runner_pod_tpl: pool["pod_template"]}
          ]
        else
          [backend: FLAME.LocalBackend, name: pool_name]
        end

      {FLAME.Pool, Keyword.merge(base_opts, pool_opts)}
    end
  end

  defp parse_jobs(jobs_file) do
    for job <- jobs_file["jobs"], into: %{} do
      pool_name = String.to_atom(job["pool"])

      route = %{
        script: String.to_atom(job["script"]),
        function: String.to_atom(job["function"]),
        pool: pool_name
      }

      {job["path"], route}
    end
  end
end

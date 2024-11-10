defmodule Flampy.MixProject do
  use Mix.Project

  def project do
    [
      app: :flampy,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Flampy.Application, [Mix.env()]},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 1.0"},
      {:erlport, "~> 0.11.0"},
      {:flame, "~> 0.5"},
      {:flame_k8s_backend, "~> 0.5.0"},
      {:jason, "~> 1.0"},
      {:plug, "~> 1.0"},
      {:yaml_elixir, "~> 2.11"}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end

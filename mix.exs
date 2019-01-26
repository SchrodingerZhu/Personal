defmodule Personal.Mixfile do
  use Mix.Project

  def project do
    [
      app: :personal,
      version: "0.1.0",
      elixir: "~> 1.7.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {Personal.Application, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ace, "~> 0.18.0"},
      {:memento, "~> 0.2.1"},
      {:cmark, "~> 0.7"},
      {:raxx_static, "~> 0.7.0"},
      {:exsync, "~> 0.2.3"},
      {:comeonin, "~> 4.1"},
      {:argon2_elixir, "~> 1.3"},
      {:kcl, "~> 1.1"},
      {:exqueue, "~> 0.1.2"},
      {:uuid, "~> 1.1"}
    ]
  end

  defp aliases() do
    []
  end
end

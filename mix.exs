defmodule Personal.Mixfile do
  use Mix.Project

  def project do
    [
      app: :personal,
      version: "0.1.0",
      elixir: "~> 1.8.0-rc.1",
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
      {:ace, "~> 0.18"},
      {:memento, "~> 0.2"},
      {:cmark, "~> 0.7"},
      {:raxx_static, github: "schrodingerzhu/raxx_static"},
      {:exsync, "~> 0.2"},
      {:comeonin, "~> 4.1"},
      {:argon2_elixir, "~> 1.3"},
      {:kcl, "~> 1.1"},
      {:uuid, "~> 1.1"},
      {:raxx_logger, "~> 0.2"},
      {:raxx_view, "~> 0.1"}
    ]
  end

  defp aliases() do
    []
  end
end

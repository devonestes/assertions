defmodule Assertions.MixProject do
  use Mix.Project

  def project do
    [
      app: :assertions,
      version: "0.20.1",
      elixir: "~> 1.17",
      deps: deps(),
      description: description(),
      package: package(),
      name: "Assertions",
      source_url: "https://github.com/devonestes/assertions",
      docs: [
        main: "Assertions",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  defp description do
    "Helpful functions with great error messages to help you write better tests."
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md LICENSE .formatter.exs),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/devonestes/assertions"}
    ]
  end

  defp deps() do
    [
      {:ex_doc, "~> 0.34", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.11", only: [:dev, :test], runtime: false},
      {:absinthe, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end

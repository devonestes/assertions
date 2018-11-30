defmodule Assertions.MixProject do
  use Mix.Project

  def project do
    [
      app: :assertions,
      version: "0.5.0",
      elixir: "~> 1.5",
      deps: [{:ex_doc, "~> 0.19", only: :dev, runtime: false}],
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
    "Helpful functions for writing better tests."
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/devonestes/assertions"}
    ]
  end
end

defmodule Assertions.MixProject do
  use Mix.Project

  @source_url "https://github.com/devonestes/assertions"

  def project do
    [
      app: :assertions,
      version: "0.19.0",
      elixir: "~> 1.7",
      deps: deps(),
      description: description(),
      package: package(),
      name: "Assertions",
      docs: docs()
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
      files: ~w(lib mix.exs CHANGELOG.md README.md LICENSE .formatter.exs),
      licenses: ["MIT"],
      links: %{
        "Changelog" => "https://hexdocs.pm/assertions/changelog.html",
        "GitHub" => @source_url
      }
    ]
  end

  defp deps() do
    [
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.3", only: [:dev, :test], runtime: false},
      {:absinthe, "~> 1.5.0-rc.5", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["CHANGELOG.md", "README.md"],
      main: "readme",
      source_url: @source_url
    ]
  end
end

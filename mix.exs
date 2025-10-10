defmodule Unpoly.MixProject do
  use Mix.Project

  @version "1.3.0"
  @description "Plug adapter for Unpoly, the unobtrusive JavaScript framework."
  @source_url "https://github.com/webstronauts/ex_unpoly"

  def project do
    [
      app: :unpoly,
      version: @version,
      elixir: "~> 1.14",
      deps: deps(),

      # Hex
      package: package(),
      description: @description,

      # Docs
      name: "Unpoly",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :plug]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.15", only: :dev, runtime: false},
      {:phoenix, "~> 1.4"},
      {:plug, "~> 1.8"},
      {:poison, "~> 3.1", only: [:dev, :test]}
    ]
  end

  defp docs() do
    [
      main: "Unpoly",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp package() do
    [
      maintainers: ["Robin van der Vleuten"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end

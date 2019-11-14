defmodule Unpoly.MixProject do
  use Mix.Project

  @version "1.1.0"
  @description "Plug adapter for Unpoly, the unobtrusive JavaScript framework."

  def project do
    [
      app: :ex_unpoly,
      version: @version,
      elixir: "~> 1.9",
      deps: deps(),

      # Hex
      package: package(),
      description: @description,

      # Docs
      name: "Unpoly",
      docs: [
        main: "Unpoly",
        source_ref: "v#{@version}",
        source_url: "https://github.com/webstronauts/ex_unpoly"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :plug]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.15", only: :dev},
      {:plug, "~> 1.8"}
    ]
  end

  defp package() do
    [
      maintainers: ["Robin van der Vleuten"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/webstronauts/ex_unpoly"}
    ]
  end
end

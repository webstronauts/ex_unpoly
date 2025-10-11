# ex_unpoly

[![Build Status](https://img.shields.io/github/actions/workflow/status/webstronauts/ex_unpoly/test.yml?branch=main&style=flat-square)](https://github.com/webstronauts/ex_unpoly/actions?query=workflow%3Atest)
[![Hex.pm](https://img.shields.io/hexpm/v/unpoly.svg?style=flat-square)](https://hex.pm/packages/unpoly)
[![Hexdocs.pm](https://img.shields.io/badge/hex-docs-blue.svg?style=flat-square)](https://hexdocs.pm/unpoly/)

A Plug adapter and helpers for Unpoly, the unobtrusive JavaScript framework.

## Installation

To use Unpoly, you can add it to your application's dependencies.

```elixir
def deps do
  [
    {:unpoly, "~> 3.0"}
  ]
end
```

## Usage

You can use the plug within your pipeline.

```elixir
defmodule MyApp.Endpoint do
  plug Logger
  plug Unpoly
  plug MyApp.Router
end
```

To find out more, head to the [online documentation]([https://hexdocs.pm/ex_unpoly).

## Changelog

Please see [CHANGELOG](CHANGELOG.md) for more information on what has changed recently.

## Contributing

Clone the repository and run `mix test`. To generate docs, run `mix docs`.

## Credits

As it's just a simple port of Ruby to Elixir. All credits should go to the Unpoly team and their [unpoly](https://github.com/unpoly/unpoly) library.

- [Robin van der Vleuten](https://github.com/robinvdvleuten)
- [All Contributors](../../contributors)

## License

The MIT License (MIT). Please see [License File](LICENSE) for more information.

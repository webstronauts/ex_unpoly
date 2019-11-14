# ex_unpoly

[![Build Status](https://travis-ci.org/webstronauts/ex_unpoly.svg?branch=master&style=flat-square)](https://travis-ci.org/webstronauts/ex_unpoly)
[![Hex.pm](https://img.shields.io/hexpm/v/ex_unpoly.svg)](https://hex.pm/packages/ex_unpoly)

A Plug adapter and helpers for Unpoly, the unobtrusive JavaScript framework.

## Installation

To use Unpoly, you can add it to your application's dependencies.

```elixir
def deps do
  [
    {:ex_unpoly, "~> 1.0"}
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

As it's just a simple port of Ruby to Elixir. All credits should go to the Unpoly team and their [unpoly](https://github.com/unpoly/unpoly) gem.

- [Robin van der Vleuten](https://github.com/robinvdvleuten)
- [All Contributors](../../contributors)

## License

The MIT License (MIT). Please see [License File](LICENSE) for more information.

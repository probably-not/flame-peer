# FlamePeer

![Elixir CI](https://github.com/probably-not/flame-peer/actions/workflows/pipeline.yaml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Hex version badge](https://img.shields.io/hexpm/v/flame_peer.svg)](https://hex.pm/packages/flame_peer)

A FLAME backend for Erlang `:peer` nodes.

Why? When testing, using `:peer` nodes more closely mimics the behavior of properly created node clusters. `:peer` nodes are essentially truely isolated nodes, communicating back to the primary node via Erlang Distribution.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `flame_peer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:flame_peer, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/flame_peer>.


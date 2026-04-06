defmodule FlamePeerTest do
  use ExUnit.Case

  doctest FlamePeer

  test "Code.loaded?" do
    assert Code.loaded?(FlamePeer)
  end
end

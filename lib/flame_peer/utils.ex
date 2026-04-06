defmodule FlamePeer.Utils do
  @moduledoc false

  require Logger

  def log(%FlamePeer.Config{log: nil}, _msg) do
    :ok
  end

  def log(%FlamePeer.Config{log: false}, _msg) do
    :ok
  end

  def log(%FlamePeer.Config{log: level}, msg) when is_atom(level) do
    Logger.log(level, msg)
  end

  def with_elapsed_ms(func) when is_function(func, 0) do
    {micro, result} = :timer.tc(func)
    {result, div(micro, 1000)}
  end
end

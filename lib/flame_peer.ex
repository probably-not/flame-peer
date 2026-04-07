defmodule FlamePeer do
  @moduledoc """
  `FlamePeer` provides a FLAME backend for Erlang `:peer` nodes.

  ## How Does It Work?

  `FlamePeer` uses Erlang's `:peer` module in order to create `:peer` nodes.
  This backend can be used to mimic a realistic FLAME cluster with real, isolated nodes that run on the local machine.
  It should generally be reserved for running in test and development environments to fully mimic the FLAME experience while staying fully local.

  ## Usage

  To use, you must tell FLAME to use the `FlamePeer` backend by default.
  This can be set via application configuration in your `config/dev.exs` and `config/test.exs`:

  ```elixir
  config :flame, :backend, FlamePeer
  ```

  ### Required Configurations

  * `:app` - The name of your application. Defaults to `System.get_env("RELEASE_NAME")` in a release. However, since this backend is typically
  used in development and testing environments, it must be set on the configuration.

  ### Optional Configurations

  * `:boot_timeout` - A timeout for booting a new node. Defaults to 30_000 (30 seconds).

  * `:peer_applications` - A list of peer applications to enforce starting on the peer node.
  Erlang `:peer` nodes don't automatically start any applications on startup, so this configuration defines which applications
  should be initialized on startup. Defaults to the `:app` value. If your application needs other applications to start up automatically,
  they must be specified in this option. The `:flame` and `:flame_peer` applications are automatically enforced to be in this list, to ensure
  that the necessary processes for FLAME and FlamePeer are properly started at all times.

  ## Environment Variables

  `:peer` nodes *do not* inherit the environment variables of the parent.
  You must explicit provide the environment that you would like to forward to the
  machine. For example, if your FLAME's are starting your Ecto repos, you can copy
  the env from the parent:

  ```elixir
  config :flame, FlamePeer,
    env: %{
      "DATABASE_URL" => System.fetch_env!("DATABASE_URL"),
      "POOL_SIZE" => "1"
    }
  ```

  Or pass the env to each pool:

  ```elixir
  {FLAME.Pool,
    name: MyRunner,
    backend: {FlamePeer, env: %{"DATABASE_URL" => System.fetch_env!("DATABASE_URL")}}
  }
  ```
  """

  @behaviour FLAME.Backend

  import FlamePeer.Utils

  alias FlamePeer.BackendState
  alias FlamePeer.PeerNode
  alias FlamePeer.Utils

  require Logger

  @impl true
  def init(opts) do
    app_config = Application.get_env(:flame, __MODULE__) || []
    {:ok, BackendState.new(opts, app_config)}
  end

  @impl true
  # The following TODO is from `FLAME.FlyBackend`. We should track it to ensure that we mirror the behavior properly.
  # TODO explore spawn_request
  def remote_spawn_monitor(%BackendState{} = state, term) do
    case term do
      func when is_function(func, 0) ->
        {pid, ref} = Node.spawn_monitor(state.runner_node_name, func)
        {:ok, {pid, ref}}

      {mod, fun, args} when is_atom(mod) and is_atom(fun) and is_list(args) ->
        {pid, ref} = Node.spawn_monitor(state.runner_node_name, mod, fun, args)
        {:ok, {pid, ref}}

      other ->
        raise ArgumentError,
              "expected a null arity function or {mod, func, args}. Got: #{inspect(other)}"
    end
  end

  @impl true
  def system_shutdown do
    System.stop()
  end

  @impl true
  def remote_boot(%BackendState{parent_ref: parent_ref} = state) do
    {peer_node, req_connect_time} =
      with_elapsed_ms(fn ->
        PeerNode.start_peer(state.config.peer_applications, state.runner_env)
      end)

    Utils.log(state.config, "#{inspect(__MODULE__)} #{inspect(node())} Peer Node created in #{req_connect_time}ms")

    remaining_connect_window = state.config.boot_timeout - req_connect_time

    case Node.ping(peer_node) do
      :pong ->
        remote_terminator_pid =
          receive do
            {^parent_ref, {:remote_up, remote_terminator_pid}} ->
              remote_terminator_pid
          after
            remaining_connect_window ->
              Logger.error("failed to connect to Peer Node within #{state.config.boot_timeout}ms")
              exit(:timeout)
          end

        new_state = %{
          state
          | remote_terminator_pid: remote_terminator_pid,
            runner_node_name: node(remote_terminator_pid)
        }

        {:ok, remote_terminator_pid, new_state}

      :pang ->
        {:error, :nodedown}
    end
  end

  @impl true
  def handle_info(msg, %BackendState{} = state) do
    Utils.log(state.config, "Missed message sent to FlamePeer Process #{inspect(self())}: #{inspect(msg)}")
    {:noreply, state}
  end
end

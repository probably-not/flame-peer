defmodule FlamePeer.PeerNode do
  @moduledoc false

  def start_peer(peer_applications, env) do
    node_name = :peer.random_name()
    caller = self()

    {:ok, controller_pid} =
      :peer.start_link(%{
        name: node_name,
        wait_boot: {caller, :peer_ready},
        args: peer_args(),
        env: Enum.map(env, fn {k, v} -> {maybe_charlist(k), maybe_charlist(v)} end)
      })

    peer =
      receive do
        {:peer_ready, {:started, peer, ^controller_pid}} -> peer
      end

    add_code_paths(peer)
    transfer_configuration(peer)
    ensure_apps_started(peer, peer_applications)

    peer
  end

  defp peer_args do
    args = [~c"-hidden"]
    args = maybe_add_cookie_args(args)
    in_release? = System.get_env("RELEASE_ROOT") != nil

    if in_release? do
      add_release_boot!(args)
    else
      args
    end
  end

  defp maybe_add_cookie_args(args) do
    case Node.get_cookie() do
      :nocookie -> args
      cookie -> [~c"-setcookie", Atom.to_charlist(cookie) | args]
    end
  end

  defp add_release_boot!(args) do
    release_root = System.fetch_env!("RELEASE_ROOT")
    release_vsn = System.fetch_env!("RELEASE_VSN")

    boot_path = Path.join([release_root, "releases", release_vsn, "start_clean"])
    boot_file = boot_path <> ".boot"

    if not File.exists?(boot_file) do
      raise RuntimeError, """
      The current running node was detected to be part of a mix release,
      with the `RELEASE_ROOT` environment variable set to
      #{release_root} and the `RELEASE_VSN` environment
      variable set to #{release_vsn}.

      We tried to load the `start_clean` bootfile from #{boot_file},
      but this file does not exist.
      """
    end

    release_lib = Path.join(release_root, "lib")

    [
      ~c"-boot",
      String.to_charlist(boot_path),
      ~c"-boot_var",
      ~c"RELEASE_LIB",
      String.to_charlist(release_lib)
      | args
    ]
  end

  defp rpc(node, module, function, args) do
    :rpc.block_call(node, module, function, args)
  end

  defp add_code_paths(node) do
    rpc(node, :code, :add_paths, [:code.get_path()])
  end

  defp transfer_configuration(node) do
    Enum.each(Application.loaded_applications(), fn {app_name, _, _} ->
      app_name
      |> Application.get_all_env()
      |> Enum.each(fn {key, primary_config} ->
        rpc(node, Application, :put_env, [app_name, key, primary_config, [persistent: true]])
      end)
    end)
  end

  defp ensure_apps_started(node, peer_applications) do
    Enum.reduce(peer_applications, MapSet.new(), fn app, started ->
      maybe_start_app(node, app, started)
    end)
  end

  defp maybe_start_app(node, app, started) do
    if Enum.member?(started, app) do
      started
    else
      case rpc(node, Application, :ensure_all_started, [app]) do
        {:ok, new_apps} -> MapSet.union(started, MapSet.new(new_apps))
        {:error, _reason} -> started
      end
    end
  end

  defp maybe_charlist(value) when is_list(value), do: value
  defp maybe_charlist(value) when is_binary(value), do: String.to_charlist(value)
end

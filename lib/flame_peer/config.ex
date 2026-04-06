defmodule FlamePeer.Config do
  @moduledoc false

  alias __MODULE__

  require Logger

  @valid_opts [
    :log,
    :env,
    :boot_timeout,
    :app,
    :peer_applications,
    # We don't use this, but it seems to be passed in automatically as part of the config options.
    # In the FLAME.FlyBackend it's only found in the valid opts list, and isn't found anywhere else in the code.
    :terminator_sup
  ]

  @derive {Inspect, only: [:boot_timeout, :app, :local_ip]}

  defstruct log: nil,
            env: %{},
            boot_timeout: nil,
            app: nil,
            peer_applications: [],
            local_ip: nil

  def new(opts, config) do
    default = %Config{
      log: Keyword.get(config, :log, false),
      boot_timeout: 30_000,
      app: System.get_env("RELEASE_NAME")
    }

    provided_opts =
      config
      |> Keyword.merge(opts)
      |> Keyword.validate!(@valid_opts)

    %Config{} = config = Map.merge(default, Map.new(provided_opts))

    config
    |> validate_app_name!()
    |> validate_local_ip!()
  end

  defp validate_app_name!(%Config{app: nil}) do
    raise ArgumentError, "You must specify the app for the FlameEC2 backend"
  end

  defp validate_app_name!(%Config{} = config) do
    config
  end

  defp validate_local_ip!(%Config{local_ip: nil}) do
    raise ArgumentError, "Could not extract the local IPv4 for the instance"
  end

  defp validate_local_ip!(%Config{} = config) do
    config
  end
end

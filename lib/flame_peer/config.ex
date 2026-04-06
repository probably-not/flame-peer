defmodule FlamePeer.Config do
  @moduledoc false

  alias __MODULE__

  require Logger

  # This is compiled with the current mix project, so locally we should have the correct app name.
  # In a "production" environment, it's using the RELEASE_NAME variable, but since this backend
  # is meant for testing and development, this should be "good enough".
  @app_name Mix.Project.config()[:app]

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

  @derive {Inspect, only: [:boot_timeout, :app]}

  defstruct log: nil,
            env: %{},
            boot_timeout: nil,
            app: nil,
            peer_applications: []

  def new(opts, config) do
    default = %Config{
      log: Keyword.get(config, :log, false),
      boot_timeout: 30_000,
      app: System.get_env("RELEASE_NAME") || @app_name
    }

    provided_opts =
      config
      |> Keyword.merge(opts)
      |> Keyword.validate!(@valid_opts)

    %Config{} = config = Map.merge(default, Map.new(provided_opts))

    validate_app_name!(config)
  end

  defp validate_app_name!(%Config{app: nil}) do
    raise ArgumentError, "You must specify the app for the FlamePeer backend"
  end

  defp validate_app_name!(%Config{} = config) do
    config
  end
end

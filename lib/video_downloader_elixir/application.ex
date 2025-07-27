defmodule VideoDownloaderElixir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      VideoDownloaderElixirWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:video_downloader_elixir, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: VideoDownloaderElixir.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: VideoDownloaderElixir.Finch},
      # Start a worker by calling: VideoDownloaderElixir.Worker.start_link(arg)
      # {VideoDownloaderElixir.Worker, arg},
      # Start to serve requests, typically the last entry
      VideoDownloaderElixirWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: VideoDownloaderElixir.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VideoDownloaderElixirWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

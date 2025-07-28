defmodule VideoDownloaderElixirWeb.Core.Router do
  use VideoDownloaderElixirWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {VideoDownloaderElixirWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :download do
    plug :accepts, ["*/*"]
  end

  scope "/", VideoDownloaderElixirWeb.Controllers do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Página de download como LiveView
  import Phoenix.LiveView.Router
  scope "/", VideoDownloaderElixirWeb.Pages do
    pipe_through :browser
    live "/downloader", DownloaderLive, :show
  end

  # Rotas API para download de vídeos/músicas
  scope "/api", VideoDownloaderElixirWeb.Controllers do
    pipe_through :api
    post "/resolutions", DownloaderController, :resolutions
  end

  # Rotas de download com pipeline específico para dados binários
  scope "/api", VideoDownloaderElixirWeb.Controllers do
    pipe_through :download
    post "/download", DownloaderController, :download
    get "/download", DownloaderController, :download
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:video_downloader_elixir, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard"
    end
  end
end

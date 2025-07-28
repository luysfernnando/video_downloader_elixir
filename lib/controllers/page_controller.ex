defmodule VideoDownloaderElixirWeb.Controllers.PageController do
  use VideoDownloaderElixirWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

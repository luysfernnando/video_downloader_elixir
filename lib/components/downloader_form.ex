defmodule VideoDownloaderElixirWeb.Components.DownloaderForm do
  use Phoenix.LiveComponent

  @doc "Formulário DaisyUI para buscar resoluções e baixar vídeos/músicas."
  def render(assigns) do
    ~H"""
    <form id="downloader-form" phx-submit="fetch_resolutions" class="flex flex-row gap-2">
      <input name="url" type="text" placeholder="Cole o link do vídeo (YouTube, Facebook, Instagram)" class="input input-bordered flex-1" required value={@url || ""} />
      <button class="btn btn-primary" type="submit">Buscar</button>
    </form>
    """
  end
end

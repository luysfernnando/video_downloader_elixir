defmodule VideoDownloaderElixirWeb.Components.DownloaderResolutions do
  use Phoenix.LiveComponent

  @doc "Lista de resoluções disponíveis para download."
  def render(assigns) do
    ~H"""
    <div>
      <%= if @formats && @formats != [] do %>
        <div id="download-form" class="flex flex-col gap-2 mt-2">
          <label class="label">Escolha a resolução:</label>
          <select id="format-select" class="select select-bordered w-full" required onchange="updateDownloadLinks()">
            <%= for format <- @formats do %>
              <option value={format.id}><%= format.desc %></option>
            <% end %>
          </select>
          <div class="flex gap-2 mt-2">
            <a
              id="video-download"
              class="btn btn-success flex-1 btn-hover-effect"
              href={"/api/download?url=" <> URI.encode_www_form(@url) <> "&format_id=" <> (List.first(@formats)[:id] || "") <> "&type=video"}
              download
              onclick="showFlashSuccess('Arquivo salvo com sucesso!')"
            >
              Baixar MP4
            </a>
            <a
              id="audio-download"
              class="btn btn-accent flex-1 btn-hover-effect"
              href={"/api/download?url=" <> URI.encode_www_form(@url) <> "&format_id=" <> (List.first(@formats)[:id] || "") <> "&type=audio"}
              download
              onclick="showFlashSuccess('Arquivo salvo com sucesso!')"
            >
              Baixar MP3
            </a>
          </div>
        </div>

        <script>
          function updateDownloadLinks() {
            const select = document.getElementById('format-select');
            const videoLink = document.getElementById('video-download');
            const audioLink = document.getElementById('audio-download');
            const selectedFormat = select.value;
            const url = '<%= @url %>';
            videoLink.href = `/api/download?url=${encodeURIComponent(url)}&format_id=${selectedFormat}&type=video`;
            audioLink.href = `/api/download?url=${encodeURIComponent(url)}&format_id=${selectedFormat}&type=audio`;
          }

          function showFlashSuccess(msg) {
            let flash = document.createElement('div');
            flash.className = 'alert alert-success fixed top-4 left-1/2 -translate-x-1/2 z-50 shadow-lg animate-fade-in';
            flash.innerHTML = `<span>${msg}</span>`;
            document.body.appendChild(flash);
            setTimeout(() => flash.remove(), 3500);
          }
        </script>
      <% end %>
    </div>
    """
  end
end

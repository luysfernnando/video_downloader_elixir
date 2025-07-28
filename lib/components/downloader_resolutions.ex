defmodule VideoDownloaderElixirWeb.Components.DownloaderResolutions do
  use Phoenix.LiveComponent

  @doc "Lista de resoluções disponíveis para download."
  def render(assigns) do
    ~H"""
    <div>
      <%= if @formats && @formats != [] do %>
        <div id="download-form" class="flex flex-col gap-2 mt-2">
          <label class="label">Escolha a resolução:</label>
          <select id="format-select" class="select select-bordered w-full" required>
            <%= for format <- @formats do %>
              <option value={format.id}><%= format.desc %></option>
            <% end %>
          </select>
          <div class="flex gap-2 mt-2">
            <a
              id="video-download"
              href={"/api/download?url=" <> URI.encode_www_form(@url) <> "&format_id=" <> (List.first(@formats)[:id] || "") <> "&type=video"}
              class="btn btn-success flex-1 btn-hover-effect"
              download
              onclick="showFlashSuccess('Download de vídeo iniciado!')"
            >
              Baixar MP4
            </a>
            <a
              id="audio-download"
              href={"/api/download?url=" <> URI.encode_www_form(@url) <> "&format_id=" <> (List.first(@formats)[:id] || "") <> "&type=audio"}
              class="btn btn-accent flex-1 btn-hover-effect"
              download
              onclick="showFlashSuccess('Download de áudio iniciado!')"
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
            flash.className = 'alert alert-success fixed top-6 left-1/2 -translate-x-1/2 z-50 shadow-lg animate-fade-in flex items-center gap-2 px-6 py-3 text-lg font-semibold';
            flash.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2l4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg><span>${msg}</span>`;
            document.body.appendChild(flash);
            setTimeout(() => {
              flash.classList.add('animate-fade-out');
              setTimeout(() => flash.remove(), 500);
            }, 2500);
          }

          document.getElementById('format-select').addEventListener('change', updateDownloadLinks);
        </script>
      <% end %>
    </div>
    """
  end

  def handle_event("format_selected", %{"value" => format_id}, socket) do
    # Atualiza os botões com o novo format_id selecionado
    send_update(__MODULE__, id: socket.assigns.id, format_id: format_id)
    {:noreply, socket}
  end
end

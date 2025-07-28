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
              href={"/api/download?url=" <> URI.encode_www_form(@url) <> "&format_id=" <> (List.first(@formats)[:id] || "") <> "&type=video" <> if(@download_id, do: "&download_id=" <> @download_id, else: "")}
              class="btn btn-success flex-1 btn-hover-effect"
              download
              phx-click="start_download"
              phx-value-format_id={List.first(@formats)[:id] || ""}
              phx-value-type="video"
            >
              Baixar MP4
            </a>
            <a
              id="audio-download"
              href={"/api/download?url=" <> URI.encode_www_form(@url) <> "&format_id=" <> (List.first(@formats)[:id] || "") <> "&type=audio" <> if(@download_id, do: "&download_id=" <> @download_id, else: "")}
              class="btn btn-accent flex-1 btn-hover-effect"
              download
              phx-click="start_download"
              phx-value-format_id={List.first(@formats)[:id] || ""}
              phx-value-type="audio"
            >
              Baixar MP3
            </a>
          </div>
        </div>

        <div id="toast-container" class="fixed top-8 left-1/2 -translate-x-1/2 z-50 flex flex-col items-center space-y-2"></div>

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

          function showToast(msg) {
            let container = document.getElementById('toast-container');
            if (!container) {
              container = document.createElement('div');
              container.id = 'toast-container';
              container.className = 'fixed top-8 left-1/2 -translate-x-1/2 z-50 flex flex-col items-center space-y-2';
              document.body.appendChild(container);
            }
            let toast = document.createElement('div');
            toast.className = 'toast toast-top toast-center bg-success text-base-100 shadow-lg animate-fade-in px-6 py-3 rounded-lg flex items-center gap-2 font-semibold text-lg';
            toast.innerHTML = `<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"stroke-current shrink-0 h-6 w-6\" fill=\"none\" viewBox=\"0 0 24 24\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M9 12l2 2l4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z\" /></svg><span>${msg}</span>`;
            container.appendChild(toast);
            setTimeout(() => {
              toast.classList.add('animate-fade-out');
              setTimeout(() => toast.remove(), 500);
            }, 2500);
            return true;
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

defmodule VideoDownloaderElixirWeb.Pages.DownloaderLive do
  use Phoenix.LiveView, layout: {VideoDownloaderElixirWeb.Layouts, :root}
  alias VideoDownloaderElixirWeb.Components.{DownloaderForm, DownloaderResolutions}
  alias VideoDownloaderElixir.Services.{DownloaderService, MetadataCache, DownloadProgress}

  def mount(params, _session, socket) do
    url = Map.get(params, "link")
    if url do
      # Inicia busca de metadados de forma otimizada
      case MetadataCache.get_metadata(url) do
        {:ok, meta} ->
          # Metadados já em cache - resposta instantânea
          case DownloaderService.list_resolutions(url) do
            {:ok, formats} ->
              {:ok, assign(socket, url: url, formats: formats, meta: meta, error: nil, loading: false, download_id: nil, download_progress: 0, download_status: nil, download_url: nil)}
            {:error, msg} ->
              {:ok, assign(socket, url: url, formats: [], meta: meta, error: msg, loading: false, download_id: nil, download_progress: 0, download_status: nil, download_url: nil)}
          end
        {:loading, _url} ->
          # Metadados sendo carregados - mostra loading
          case DownloaderService.list_resolutions(url) do
            {:ok, formats} ->
              {:ok, assign(socket, url: url, formats: formats, meta: nil, error: nil, loading: true, download_id: nil, download_progress: 0, download_status: nil, download_url: nil)}
            {:error, msg} ->
              {:ok, assign(socket, url: url, formats: [], meta: nil, error: msg, loading: true, download_id: nil, download_progress: 0, download_status: nil, download_url: nil)}
          end
        {:error, msg} ->
          {:ok, assign(socket, url: url, formats: [], meta: nil, error: msg, loading: false, download_id: nil, download_progress: 0, download_status: nil, download_url: nil)}
      end
    else
      {:ok, assign(socket, url: nil, formats: [], meta: nil, error: nil, loading: false, download_id: nil, download_progress: 0, download_status: nil, download_url: nil)}
    end
  end

  def handle_event("fetch_resolutions", %{"url" => url}, socket) do
    # Inicia busca de metadados de forma otimizada
    case MetadataCache.get_metadata(url) do
      {:ok, meta} ->
        # Metadados já em cache - resposta instantânea
        case DownloaderService.list_resolutions(url) do
          {:ok, formats} ->
            {:noreply, assign(socket, url: url, formats: formats, meta: meta, error: nil, loading: false)}
          {:error, msg} ->
            {:noreply, assign(socket, error: msg, formats: [], url: url, meta: meta, loading: false)}
        end
      {:loading, _url} ->
        # Metadados sendo carregados - mostra loading
        case DownloaderService.list_resolutions(url) do
          {:ok, formats} ->
            {:noreply, assign(socket, url: url, formats: formats, meta: nil, error: nil, loading: true)}
          {:error, msg} ->
            {:noreply, assign(socket, error: msg, formats: [], url: url, meta: nil, loading: true)}
        end
      {:error, msg} ->
        {:noreply, assign(socket, error: msg, formats: [], url: url, meta: nil, loading: false)}
    end
  end

  def handle_event("start_download", %{"url" => url, "format_id" => format_id, "type" => type}, socket) do
    case DownloadProgress.start_download(url, format_id, String.to_atom(type)) do
      {:ok, download_id} ->
        # Assina o canal de progresso
        Phoenix.PubSub.subscribe(VideoDownloaderElixir.PubSub, "download:#{download_id}")

        {:noreply,
         socket
         |> put_flash(:info, "Download iniciado! Acompanhe o progresso abaixo.")
         |> assign(download_id: download_id, download_progress: 0, download_status: :starting)}
      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, "Erro ao iniciar download: #{error}")}
    end
  end

  # Recebe atualizações de progresso via PubSub
  def handle_info({:progress_update, download}, socket) do
    {:noreply,
     socket
     |> assign(download_progress: download.progress, download_status: download.status)}
  end

  def handle_info({:download_complete, download}, socket) do
    case Map.get(download, :result) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Erro no download: resultado não encontrado")
         |> assign(download_status: :error)}
      {:ok, _data} ->
        # Cria link de download
        download_url = "/api/download?url=#{URI.encode(download.url)}&format_id=#{download.format_id}&type=#{download.type}"
        {:noreply,
         socket
         |> put_flash(:success, "Download concluído! Clique no botão para baixar o arquivo.")
         |> assign(download_progress: 100, download_status: :completed, download_url: download_url)}
      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, "Erro no download: #{error}")
         |> assign(download_status: :error)}
    end
  end

  def handle_info({:download_error, download}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "Erro no download: #{download.error}")
     |> assign(download_status: :error)}
  end

  # Recebe metadados via PubSub quando ficam prontos
  def handle_info({:metadata_ready, meta}, socket) do
    {:noreply, assign(socket, meta: meta, loading: false)}
  end

  def handle_info({:metadata_error, error}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "Erro ao carregar metadados: #{error}")
     |> assign(loading: false)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200">
      <div class="card w-full max-w-md bg-base-100 shadow-xl card-hover">
        <div class="card-body flex flex-col gap-4">
          <h2 class="card-title justify-center text-2xl mb-2 animate-fade-in">Baixar vídeo</h2>

          <.live_component module={DownloaderForm} id="downloader-form" url={@url} />

          <%= if @loading do %>
            <div class="flex flex-col items-center gap-4 p-4 animate-slide-in">
              <div class="loading-custom"></div>
              <div class="text-center">
                <div class="font-semibold animate-pulse">Carregando informações...</div>
                <div class="text-sm opacity-70">Buscando metadados do vídeo</div>
              </div>
            </div>
          <% end %>

          <%= if @meta do %>
            <div class="flex flex-col items-center gap-2 mt-2 animate-bounce-in">
              <img src={@meta.thumbnail || "/images/placeholder.png"} class="rounded-lg w-32 h-32 object-cover border border-base-300" alt="thumbnail" />
              <div class="text-center">
                <div class="font-bold text-lg"><%= @meta.title || "Título não encontrado" %></div>
                <div class="text-sm opacity-70">
                  <%= if @meta.duration, do: "Duração: #{div(@meta.duration, 60)}m #{rem(@meta.duration, 60)}s", else: "Duração desconhecida" %><br/>
                  <%= if @meta.filesize, do: "Tamanho: #{Float.round(@meta.filesize / 1024 / 1024, 2)} MB", else: "Tamanho desconhecido" %>
                </div>
              </div>
            </div>
          <% end %>

          <.live_component module={DownloaderResolutions} id="downloader-resolutions" formats={@formats} url={@url} />

          <%= if @download_id do %>
            <div class="mt-4 p-4 bg-base-200 rounded-lg animate-slide-in">
              <div class="flex justify-between items-center mb-2">
                <span class="font-semibold">Progresso do Download</span>
                <span class="text-sm opacity-70"><%= @download_progress %>%</span>
              </div>
              <progress class="progress progress-primary w-full progress-animated" value={@download_progress} max="100"></progress>
              <%= if @download_status == :completed and @download_url do %>
                <div class="mt-3">
                  <a href={@download_url} class="btn btn-success btn-sm w-full btn-hover-effect success-pulse" download>
                    📥 Baixar Arquivo
                  </a>
                </div>
              <% end %>
            </div>
          <% end %>

          <%= if @error do %>
            <div class="alert alert-error mt-2 error-shake">
              <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span><%= @error %></span>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end

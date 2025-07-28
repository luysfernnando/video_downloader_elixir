defmodule VideoDownloaderElixirWeb.Pages.HomeLive do
  use Phoenix.LiveView, layout: {VideoDownloaderElixirWeb.Layouts, :root}
  alias VideoDownloaderElixirWeb.Components.{DownloaderForm, DownloaderResolutions}
  alias VideoDownloaderElixir.Services.{DownloaderService, MetadataCache}

  def mount(_params, _session, socket) do
    {:ok, assign(socket,
      url: nil,
      formats: [],
      meta: nil,
      basic_meta: nil,
      error: nil,
      loading: false,
      show_results: false,
      processing: false,
      download_id: nil
    )}
  end

  def handle_event("fetch_resolutions", %{"url" => url}, socket) do
    # Mostra o card de processamento instantaneamente
    socket = assign(socket,
      loading: true,
      processing: true,
      error: nil,
      show_results: false,
      basic_meta: nil,
      meta: nil,
      url: url
    )
    send(self(), {:fetch_metadata, url})
    {:noreply, socket}
  end

  def handle_info({:fetch_metadata, url}, socket) do
    # Busca metadados básicos (pode demorar, mas loading já está na tela)
    basic_meta =
      case VideoDownloaderElixir.Services.MetadataService.get_basic_metadata(url) do
        {:ok, meta} -> meta
        _ -> nil
      end
    socket = assign(socket, basic_meta: basic_meta, processing: false)
    send(self(), {:fetch_full_metadata, url})
    {:noreply, socket}
  end

  def handle_info({:fetch_full_metadata, url}, socket) do
    Phoenix.PubSub.subscribe(VideoDownloaderElixir.PubSub, "metadata:#{url}")
    case MetadataCache.get_metadata(url) do
      {:ok, meta} ->
        # Metadados completos já em cache
        case DownloaderService.list_resolutions(url) do
          {:ok, formats} ->
            {:noreply, assign(socket,
              formats: formats,
              meta: meta,
              error: nil,
              loading: false,
              show_results: true
            )}
          {:error, msg} ->
            {:noreply, assign(socket,
              error: msg,
              formats: [],
              meta: meta,
              loading: false,
              show_results: true
            )}
        end
      {:loading, _url} ->
        # Metadados completos sendo carregados
        case DownloaderService.list_resolutions(url) do
          {:ok, formats} ->
            {:noreply, assign(socket,
              formats: formats,
              meta: nil,
              error: nil,
              loading: true,
              show_results: true
            )}
          {:error, msg} ->
            {:noreply, assign(socket,
              error: msg,
              formats: [],
              meta: nil,
              loading: true,
              show_results: true
            )}
        end
      {:error, msg} ->
        {:noreply, assign(socket,
          error: msg,
          formats: [],
          meta: nil,
          loading: false,
          show_results: true
        )}
    end
  end

  # Recebe metadados completos via PubSub
  def handle_info({:metadata_ready, meta}, socket) do
    # Atualiza a tela com metadados completos
    {:noreply, assign(socket, meta: meta, loading: false, show_results: true)}
  end

  def handle_info({:metadata_error, error}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "Erro ao carregar metadados: #{error}")
     |> assign(loading: false)}
  end

  def handle_event("start_download", %{"format_id" => format_id, "type" => type}, socket) do
    # Gera um download_id único
    download_id = :crypto.hash(:sha256, "#{socket.assigns.url}-#{format_id}-#{type}") |> Base.encode16()
    Phoenix.PubSub.subscribe(VideoDownloaderElixir.PubSub, "download:#{download_id}")
    {:noreply, assign(socket, download_id: download_id)}
  end

  def handle_info({:download_complete, _}, socket) do
    {:noreply, put_flash(socket, :success, "Arquivo salvo com sucesso!")}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200">
      <div class="card w-full max-w-md bg-base-100 shadow-xl card-hover">
        <div class="card-body flex flex-col gap-4">
          <h2 class="card-title justify-center text-2xl mb-2 animate-fade-in">Video Downloader</h2>

          <.live_component module={DownloaderForm} id="downloader-form" url={@url} />

          <%= if @processing do %>
            <div class="flex flex-col items-center gap-4 p-6 animate-slide-in">
              <div class="loading loading-spinner loading-lg text-primary"></div>
              <div class="text-center">
                <div class="font-semibold text-lg animate-pulse">Processando informações do vídeo...</div>
                <div class="text-sm opacity-70 mt-2">Buscando metadados e formatos disponíveis</div>
                <div class="loading loading-dots loading-sm mt-3"></div>
              </div>
            </div>
          <% end %>

          <%= if @meta do %>
            <div class="flex flex-col items-center gap-3 mt-4 p-4 bg-base-200 rounded-lg animate-bounce-in">
              <img src={@meta.thumbnail || "/images/placeholder.png"} class="rounded-lg w-32 h-32 object-cover border border-base-300 shadow-md" alt="thumbnail" />
              <div class="text-center">
                <div class="font-bold text-lg leading-tight"><%= @meta.title || "Título não encontrado" %></div>
                <div class="text-sm opacity-70 mt-2">
                  <span class="font-semibold">Duração:</span>
                  <%= if @meta.duration, do: " #{div(@meta.duration, 60)}m #{rem(@meta.duration, 60)}s", else: " Duração desconhecida" %><br/>
                  <span class="font-semibold">Tamanho:</span>
                  <%= if @meta.filesize, do: " #{Float.round(@meta.filesize / 1024 / 1024, 2)} MB", else: " Tamanho desconhecido" %>
                </div>
              </div>
            </div>
          <% else %>
            <%= if @basic_meta do %>
              <div class="flex flex-col items-center gap-3 mt-4 p-4 bg-base-200 rounded-lg animate-bounce-in">
                <img src={@basic_meta.thumbnail || "/images/placeholder.png"} class="rounded-lg w-32 h-32 object-cover border border-base-300 shadow-md" alt="thumbnail" />
                <div class="text-center">
                  <div class="font-bold text-lg leading-tight"><%= @basic_meta.title || "Título não encontrado" %></div>
                  <div class="text-sm opacity-70 mt-2">
                    <span class="font-semibold">Duração:</span>
                    <%= if @basic_meta.duration, do: " #{div(@basic_meta.duration, 60)}m #{rem(@basic_meta.duration, 60)}s", else: " Duração desconhecida" %><br/>
                    <span class="font-semibold">Tamanho:</span>
                    <span class="animate-pulse"> Verificando...</span>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>

          <%= if !@processing and @formats && @formats != [] do %>
            <.live_component module={DownloaderResolutions} id="downloader-resolutions" formats={@formats} url={@url} download_id={@download_id} phx-click="start_download" />
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

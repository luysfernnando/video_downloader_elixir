defmodule VideoDownloaderElixir.Services.DownloadProgress do
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{downloads: %{}}}
  end

  @impl true
  def handle_call({:start_download, download_id, url, format_id, type}, _from, state) do
    # Inicia download em background
    Task.start(fn -> perform_download(download_id, url, format_id, type) end)

    # Adiciona à lista de downloads ativos
    new_downloads = Map.put(state.downloads, download_id, %{
      status: :starting,
      progress: 0,
      url: url,
      format_id: format_id,
      type: type,
      start_time: System.system_time(:millisecond)
    })

    {:reply, {:ok, download_id}, %{state | downloads: new_downloads}}
  end

  @impl true
  def handle_call({:get_progress, download_id}, _from, state) do
    case Map.get(state.downloads, download_id) do
      nil -> {:reply, {:error, :not_found}, state}
      download -> {:reply, {:ok, download}, state}
    end
  end

  @impl true
  def handle_info({:download_progress, download_id, progress}, state) do
    case Map.get(state.downloads, download_id) do
      nil -> {:noreply, state}
      download ->
        updated_download = %{download | progress: progress, status: :downloading}
        new_downloads = Map.put(state.downloads, download_id, updated_download)

        # Notifica via PubSub
        Phoenix.PubSub.broadcast(
          VideoDownloaderElixir.PubSub,
          "download:#{download_id}",
          {:progress_update, updated_download}
        )

        {:noreply, %{state | downloads: new_downloads}}
    end
  end

  @impl true
  def handle_info({:download_complete, download_id, result}, state) do
    case Map.get(state.downloads, download_id) do
      nil -> {:noreply, state}
      download ->
        # Adiciona o resultado ao download
        updated_download = Map.put(download, :result, result)
        updated_download = %{updated_download |
          status: :completed,
          progress: 100
        }
        new_downloads = Map.put(state.downloads, download_id, updated_download)

        # Notifica via PubSub
        Phoenix.PubSub.broadcast(
          VideoDownloaderElixir.PubSub,
          "download:#{download_id}",
          {:download_complete, updated_download}
        )

        {:noreply, %{state | downloads: new_downloads}}
    end
  end

  @impl true
  def handle_info({:download_error, download_id, error}, state) do
    case Map.get(state.downloads, download_id) do
      nil -> {:noreply, state}
      download ->
        updated_download = %{download |
          status: :error,
          error: error
        }
        new_downloads = Map.put(state.downloads, download_id, updated_download)

        # Notifica via PubSub
        Phoenix.PubSub.broadcast(
          VideoDownloaderElixir.PubSub,
          "download:#{download_id}",
          {:download_error, updated_download}
        )

        {:noreply, %{state | downloads: new_downloads}}
    end
  end

  defp perform_download(download_id, url, format_id, type) do
    # Inicia o download real
    result = VideoDownloaderElixir.Services.DownloaderService.download(url, format_id, type)

    case result do
      {data, 0} when is_binary(data) and byte_size(data) > 0 ->
        send(__MODULE__, {:download_complete, download_id, {:ok, data}})
      {_data, exit_code} ->
        send(__MODULE__, {:download_error, download_id, "Erro no download. Código: #{exit_code}"})
    end
  end

  # API pública
  def start_download(url, format_id, type) do
    download_id = generate_download_id()
    GenServer.call(__MODULE__, {:start_download, download_id, url, format_id, type})
  end

  def get_progress(download_id) do
    GenServer.call(__MODULE__, {:get_progress, download_id})
  end

  defp generate_download_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end

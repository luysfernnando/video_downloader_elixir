defmodule VideoDownloaderElixir.Services.MetadataCache do
  use GenServer
  alias VideoDownloaderElixir.Core.Debug

  @cache_ttl :timer.minutes(30) # Cache por 30 minutos

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Inicia o processo de limpeza de cache
    schedule_cache_cleanup()
    {:ok, %{cache: %{}, cleanup_ref: nil}}
  end

  @impl true
  def handle_call({:get_metadata, url}, _from, state) do
    alias VideoDownloaderElixir.Core.Debug
    Debug.log(:info, "🔍 MetadataCache.get_metadata chamado para: #{url}")
    case get_cached_metadata(url, state.cache) do
      {:ok, metadata} ->
        Debug.log(:info, "✅ Cache HIT no get_metadata")
        {:reply, {:ok, metadata}, state}
      :not_found ->
        Debug.log(:info, "❌ Cache MISS - iniciando busca assíncrona")
        # Inicia busca assíncrona
        Task.start(fn -> fetch_and_cache_metadata(url) end)
        {:reply, {:loading, url}, state}
      :expired ->
        Debug.log(:info, "⏰ Cache EXPIRADO - iniciando busca assíncrona")
        # Inicia busca assíncrona
        Task.start(fn -> fetch_and_cache_metadata(url) end)
        {:reply, {:loading, url}, state}
    end
  end

  @impl true
  def handle_info({:metadata_fetched, url, result}, state) do
    alias VideoDownloaderElixir.Core.Debug
    Debug.log(:info, "📬 Recebeu :metadata_fetched para: #{url}")
    case result do
      {:ok, metadata} ->
        Debug.log(:info, "✅ Metadata OK - Broadcasting via PubSub: metadata:#{url}")
        Debug.log(:info, "📊 Dados: #{inspect(metadata)}")
        # Notifica via PubSub que os metadados estão prontos
        Phoenix.PubSub.broadcast(
          VideoDownloaderElixir.PubSub,
          "metadata:#{url}",
          {:metadata_ready, metadata}
        )
        Debug.log(:info, "📡 Broadcast enviado!")
        # Atualiza cache
        new_cache = Map.put(state.cache, url, %{
          data: metadata,
          timestamp: System.system_time(:second)
        })
        {:noreply, %{state | cache: new_cache}}
      {:error, error} ->
        Debug.log(:error, "❌ Erro nos metadados - Broadcasting erro via PubSub")
        # Notifica erro via PubSub
        Phoenix.PubSub.broadcast(
          VideoDownloaderElixir.PubSub,
          "metadata:#{url}",
          {:metadata_error, error}
        )
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:cleanup_cache, state) do
    now = System.system_time(:second)
    new_cache = Map.filter(state.cache, fn {_url, %{timestamp: timestamp}} ->
      now - timestamp < @cache_ttl
    end)
    schedule_cache_cleanup()
    {:noreply, %{state | cache: new_cache}}
  end

  defp get_cached_metadata(url, cache) do
    case Map.get(cache, url) do
      nil -> :not_found
      %{data: data, timestamp: timestamp} ->
        now = System.system_time(:second)
        if now - timestamp < @cache_ttl do
          {:ok, data}
        else
          :expired
        end
    end
  end

  defp fetch_and_cache_metadata(url) do
    alias VideoDownloaderElixir.Core.Debug
    Debug.log(:info, "🚀 Iniciando fetch_and_cache_metadata para: #{url}")
    result = VideoDownloaderElixir.Services.MetadataService.get_metadata(url)
    Debug.log(:info, "📦 Resultado do fetch: #{inspect(result)}")
    Debug.log(:info, "📤 Enviando mensagem :metadata_fetched para GenServer")
    send(__MODULE__, {:metadata_fetched, url, result})
  end

  defp schedule_cache_cleanup do
    Process.send_after(self(), :cleanup_cache, :timer.minutes(5))
  end

  # API pública
  def get_metadata(url) do
    GenServer.call(__MODULE__, {:get_metadata, url}, :infinity)
  end
end

defmodule VideoDownloaderElixir.Services.MetadataService do
  @yt_dlp_cmd "yt-dlp"

  @doc "Obtém metadados do vídeo (thumbnail, título, duração, tamanho) de forma otimizada."
  def get_metadata(url) do
    # Comando otimizado para velocidade máxima
    args = [
      "-j",           # JSON output
      "--no-playlist", # Não baixar playlists
      "--no-warnings", # Sem warnings
      "--quiet",       # Modo silencioso
      url
    ]

    # Timeout reduzido para resposta rápida (removido timeout do System.cmd)
    case System.cmd(@yt_dlp_cmd, args) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, meta} ->
            {:ok, %{
              title: meta["title"] || "Título não disponível",
              duration: meta["duration"],
              thumbnail: meta["thumbnail"],
              filesize: meta["filesize"] || meta["filesize_approx"] || meta["filesize_approx"] || 0
            }}
          _ -> {:error, "Erro ao decodificar metadados"}
        end
      {_output, exit_code} ->
        {:error, "Erro ao obter metadados. Código de saída: #{exit_code}"}
    end
  end

  @doc "Obtém apenas informações básicas do vídeo (muito rápido)."
  def get_basic_metadata(url) do
    # Comando ainda mais otimizado para informações básicas
    args = [
      "-j",
      "--no-playlist",
      "--no-warnings",
      "--quiet",
      "--no-download", # Não baixar nada
      url
    ]

    case System.cmd(@yt_dlp_cmd, args) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, meta} ->
            {:ok, %{
              title: meta["title"] || "Título não disponível",
              duration: meta["duration"],
              thumbnail: meta["thumbnail"]
            }}
          _ -> {:error, "Erro ao decodificar metadados básicos"}
        end
      {_output, exit_code} ->
        {:error, "Erro ao obter metadados básicos. Código: #{exit_code}"}
    end
  end
end

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

    case System.cmd(@yt_dlp_cmd, args) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, meta} ->
            # Tenta múltiplas formas de obter o filesize
            filesize = meta["filesize"] ||
                       meta["filesize_approx"] ||
                       calculate_filesize_from_format(meta) ||
                       0

            {:ok, %{
              title: meta["title"] || "Título não disponível",
              duration: meta["duration"],
              thumbnail: meta["thumbnail"],
              filesize: filesize
            }}
          _ ->
            {:error, "Erro ao decodificar metadados"}
        end
      {_output, exit_code} ->
        {:error, "Erro ao obter metadados. Código de saída: #{exit_code}"}
    end
  end

  # Calcula o filesize a partir dos formatos disponíveis
  defp calculate_filesize_from_format(meta) do
    formats = meta["formats"] || []
    requested_format = meta["format_id"]

    # Primeiro tenta o formato requisitado
    filesize = if requested_format do
      format = Enum.find(formats, fn f -> f["format_id"] == requested_format end)
      format && (format["filesize"] || format["filesize_approx"])
    end

    # Se não encontrou, busca o maior filesize entre todos os formatos
    filesize = if !filesize || filesize == 0 do
      formats
      |> Enum.map(fn f -> f["filesize"] || f["filesize_approx"] || 0 end)
      |> Enum.max(fn -> 0 end)
      |> then(fn size -> if size > 0, do: size, else: nil end)
    else
      filesize
    end

    if filesize && filesize > 0, do: filesize, else: nil
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

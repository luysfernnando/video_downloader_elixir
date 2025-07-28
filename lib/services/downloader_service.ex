defmodule VideoDownloaderElixir.Services.DownloaderService do
  @moduledoc "Serviço para baixar vídeos e músicas de YouTube, Facebook e Instagram usando yt-dlp."

  @yt_dlp_cmd "yt-dlp"

  @doc "Retorna as resoluções disponíveis para um vídeo."
  def list_resolutions(url) do
    args = ["-F", url]
    case System.cmd(@yt_dlp_cmd, args, stderr_to_stdout: true) do
      {output, 0} ->
        parse_resolutions(output)
      {output, _} ->
        {:error, output}
    end
  end

  @doc "Baixa o vídeo ou áudio na resolução/format escolhida."
  def download(url, format_id, type) do
    # Comando otimizado para evitar corrupção e problemas de codec
    args = case type do
      :audio ->
        [
          "-f", "140",  # Formato de áudio M4A
          "-o", "-",
          "--extract-audio",
          "--audio-format", "mp3",
          "--audio-quality", "0",
          "--no-playlist",
          url
        ]
      :video ->
        # Para vídeo, usa formatos que já incluem áudio e vídeo
        # ou faz merge simples se necessário
        [
          "-f", "best[height<=#{get_height_from_format(format_id)}]",  # Melhor qualidade até a resolução desejada
          "-o", "-",
          "--no-playlist",
          url
        ]
    end

    # Executa sem capturar stderr para evitar misturar com o conteúdo do arquivo
    case System.cmd(@yt_dlp_cmd, args) do
      {data, 0} when is_binary(data) and byte_size(data) > 0 ->
        {data, 0}
      {data, 0} when byte_size(data) == 0 ->
        {"", 1}  # Arquivo vazio
      {_data, exit_code} ->
        # Em caso de erro, retorna uma tupla vazia para manter compatibilidade
        {"", exit_code}
    end
  end

  # Função auxiliar para extrair altura do format_id
  defp get_height_from_format(format_id) do
    case format_id do
      "137" -> "1080"
      "136" -> "720"
      "135" -> "480"
      "134" -> "360"
      "133" -> "240"
      _ -> "720"  # Padrão
    end
  end

  defp parse_resolutions(output) do
    # Extrai as linhas de formatos disponíveis
    lines = String.split(output, "\n")
    wanted_res = ["2160p", "1440p", "1080p", "720p"]
    formats =
      lines
      |> Enum.filter(&String.match?(&1, ~r/^\d+/))
      |> Enum.map(fn line ->
        [id | rest] = String.split(line, ~r/\s+/, parts: 2)
        desc = Enum.at(rest, 0, "")
        # Extrai apenas a resolução (ex: 2160p, 1440p, 1080p, 720p)
        res = Enum.find(wanted_res, fn r -> String.contains?(desc, r) end)
        %{id: id, desc: res}
      end)
      |> Enum.filter(fn %{desc: desc} ->
        not is_nil(desc)
      end)
      |> Enum.uniq_by(& &1.desc)
    {:ok, formats}
  end
end

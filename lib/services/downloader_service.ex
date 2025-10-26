defmodule VideoDownloaderElixir.Services.DownloaderService do
  @moduledoc """
  Serviço para baixar vídeos e músicas de YouTube, Facebook e Instagram usando yt-dlp.
  
  Suporta:
  - YouTube: resoluções padrão (720p, 1080p, etc) e áudio MP3
  - Facebook: vídeos verticais e horizontais (720x1280, 1080x1920, etc) e áudio
  - Instagram: reels e vídeos (720x1280, 1080x1920, etc) e áudio
  """

  @yt_dlp_cmd "yt-dlp"

  @doc "Retorna as resoluções disponíveis para um vídeo."
  def list_resolutions(url) do
    alias VideoDownloaderElixir.Core.Debug
    Debug.log(:info, "🎬 DownloaderService.list_resolutions chamado para: #{url}")

    # Adiciona flags para acelerar e evitar warnings
    args = [
      "-F",
      "--no-warnings",
      "--no-playlist",
      "--skip-download",
      url
    ]

    # Usa Task com timeout para evitar travamentos
    task = Task.async(fn ->
      System.cmd(@yt_dlp_cmd, args, stderr_to_stdout: true)
    end)

    case Task.yield(task, 30_000) || Task.shutdown(task) do
      {:ok, {output, 0}} ->
        Debug.log(:info, "✅ yt-dlp -F executado com sucesso")
        result = parse_resolutions(output)
        Debug.log(:info, "📊 Resultado parse_resolutions: #{inspect(result)}")
        result
      {:ok, {output, code}} ->
        Debug.log(:error, "❌ yt-dlp -F falhou com código #{code}: #{String.slice(output, 0, 200)}")
        {:error, output}
      nil ->
        Debug.log(:error, "⏱️ Timeout ao executar yt-dlp -F")
        {:error, "Timeout ao buscar resoluções"}
    end
  end

  @doc "Baixa o vídeo ou áudio na resolução/format escolhida."
  def download(url, format_id, type) do
    alias VideoDownloaderElixir.Core.Debug
    Debug.log(:info, "🎥 Iniciando download - URL: #{url}, Format: #{format_id}, Type: #{type}")

    # Cria um arquivo temporário único com extensão apropriada
    {temp_file, final_ext} = case type do
      :audio ->
        # Para áudio, o yt-dlp vai converter para mp3 automaticamente
        {"/tmp/yt-dlp-#{:erlang.unique_integer([:positive])}", ".mp3"}
      :video ->
        {"/tmp/yt-dlp-#{:erlang.unique_integer([:positive])}.mp4", ".mp4"}
    end

    # Comando otimizado para evitar corrupção e problemas de codec
    args = case type do
      :audio ->
        [
          "-f", "bestaudio",
          "-o", temp_file,
          "--extract-audio",
          "--audio-format", "mp3",
          "--audio-quality", "0",
          "--no-playlist",
          url
        ]
      :video ->
        # Para vídeo, usa arquivo temporário para garantir merge correto
        format_spec = if is_numeric_or_complex_id?(format_id) do
          "#{format_id}+bestaudio/best"
        else
          "#{format_id}+bestaudio/best"
        end

        Debug.log(:info, "📹 Format spec: #{format_spec}")

        [
          "-f", format_spec,
          "-o", temp_file,
          "--no-playlist",
          "--merge-output-format", "mp4",
          url
        ]
    end

    Debug.log(:info, "🚀 Executando yt-dlp com args: #{inspect(args)}")

    # Executa o download
    case System.cmd(@yt_dlp_cmd, args, stderr_to_stdout: true) do
      {_output, 0} ->
        # O arquivo final pode ter extensão diferente (mp3 para áudio)
        final_file = temp_file <> final_ext

        # Tenta ler o arquivo com a extensão correta
        file_to_read = if File.exists?(final_file) do
          final_file
        else
          temp_file
        end

        Debug.log(:info, "📂 Tentando ler arquivo: #{file_to_read}")

        # Lê o arquivo temporário
        case File.read(file_to_read) do
          {:ok, data} ->
            # Remove os arquivos temporários
            File.rm(temp_file)
            File.rm(final_file)
            Debug.log(:info, "✅ Download concluído - #{byte_size(data)} bytes")
            {data, 0}
          {:error, reason} ->
            Debug.log(:error, "❌ Erro ao ler arquivo temporário: #{inspect(reason)}")
            File.rm(temp_file)
            File.rm(final_file)
            {"", 1}
        end
      {output, exit_code} ->
        Debug.log(:error, "❌ yt-dlp falhou com código #{exit_code}: #{String.slice(output, 0, 500)}")
        File.rm(temp_file)
        {"", exit_code}
    end
  end

  # Verifica se o format_id é numérico ou complexo (Facebook/Instagram)
  defp is_numeric_or_complex_id?(format_id) do
    # IDs complexos do Facebook/Instagram contêm letras no final
    # Ex Facebook: "844688081403094v", "1448018849630974v"
    # Ex Instagram: "dash-1152764252955533vd", "dash-814334291528654ad"
    String.match?(format_id, ~r/^dash-\d+[a-z]+$/) or  # Instagram: dash-XXXXXvd, dash-XXXXXad
    String.match?(format_id, ~r/\d+[a-z]$/) or         # Facebook: XXXXXv
    String.match?(format_id, ~r/^\d{10,}/)             # IDs numéricos longos
  end

  defp parse_resolutions(output) do
    alias VideoDownloaderElixir.Core.Debug

    # Extrai as linhas de formatos disponíveis
    lines = String.split(output, "\n")

    formats =
      lines
      |> Enum.filter(&String.match?(&1, ~r/^\S+\s+\w+/))  # Linhas que começam com ID e extensão
      |> Enum.map(fn line ->
        parts = String.split(line, ~r/\s+/)
        id = Enum.at(parts, 0, "")
        ext = Enum.at(parts, 1, "")

        # Ignora formatos com resolução desconhecida
        if String.contains?(line, "unknown") do
          nil
        else
          # Tenta extrair resolução de diferentes formatos
          resolution = extract_resolution(line)

          if resolution do
            %{id: id, desc: resolution, ext: ext}
          else
            nil
          end
        end
      end)
      |> Enum.filter(&(&1 != nil))
      |> Enum.uniq_by(& &1.desc)
      |> Enum.sort_by(&resolution_to_number(&1.desc), :desc)  # Ordena da maior para menor

    Debug.log(:info, "📊 Formatos parseados: #{inspect(formats)}")
    {:ok, formats}
  end

  # Extrai resolução de diferentes formatos
  defp extract_resolution(line) do
    cond do
      # Formato YouTube: "720p", "1080p", etc
      String.match?(line, ~r/\d+p/) ->
        case Regex.run(~r/(\d+)p/, line) do
          [_, height] -> "#{height}p"
          _ -> nil
        end

      # Formato Facebook/Instagram: "720x1280", "1080x1920", etc
      String.match?(line, ~r/\d+x\d+/) ->
        case Regex.run(~r/(\d+)x(\d+)/, line) do
          [_, width, height] ->
            # Usa a menor dimensão (padrão da indústria)
            # Para vídeos verticais (720x1280), a resolução é 720p
            # Para vídeos horizontais (1920x1080), a resolução é 1080p
            min_dim = min(String.to_integer(width), String.to_integer(height))
            cond do
              min_dim >= 2160 -> "2160p"
              min_dim >= 1440 -> "1440p"
              min_dim >= 1080 -> "1080p"
              min_dim >= 720 -> "720p"
              min_dim >= 540 -> "540p"
              min_dim >= 480 -> "480p"
              min_dim >= 360 -> "360p"
              true -> "#{min_dim}p"
            end
          _ -> nil
        end

      # Ignora formatos simples "hd", "sd" pois são menos confiáveis
      true -> nil
    end
  end

  # Converte resolução para número para ordenação
  defp resolution_to_number(res) do
    case res do
      "2160p" -> 2160
      "1440p" -> 1440
      "1080p" -> 1080
      "720p" -> 720
      "540p" -> 540
      "480p" -> 480
      "360p" -> 360
      _ ->
        case Regex.run(~r/(\d+)p/, res) do
          [_, num] -> String.to_integer(num)
          _ -> 0
        end
    end
  end
end

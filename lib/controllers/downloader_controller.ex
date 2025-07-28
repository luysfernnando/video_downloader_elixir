defmodule VideoDownloaderElixirWeb.Controllers.DownloaderController do
  use VideoDownloaderElixirWeb, :controller

  alias VideoDownloaderElixir.Services.DownloaderService

  def resolutions(conn, %{"url" => url}) do
    case DownloaderService.list_resolutions(url) do
      {:ok, formats} ->
        json(conn, %{formats: formats})
      {:error, msg} ->
        conn |> put_status(400) |> json(%{error: msg})
    end
  end

  def download(conn, %{"url" => url, "format_id" => format_id, "type" => type} = params) do
    case DownloaderService.download(url, format_id, String.to_atom(type)) do
      {data, 0} when is_binary(data) and byte_size(data) > 0 ->
        {content_type, filename} = case type do
          "audio" -> {"audio/mpeg", "audio.mp3"}
          "video" -> {"video/mp4", "video.mp4"}
        end

        # PubSub: notifica download concluído se houver download_id
        if download_id = params["download_id"] do
          Phoenix.PubSub.broadcast(VideoDownloaderElixir.PubSub, "download:#{download_id}", {:download_complete, %{filename: filename}})
        end

        conn
        |> put_resp_content_type(content_type)
        |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
        |> put_resp_header("content-length", "#{byte_size(data)}")
        |> put_resp_header("accept-ranges", "bytes")
        |> put_resp_header("cache-control", "no-cache")
        |> send_resp(200, data)
      {_data, exit_code} ->
        conn
        |> put_status(500)
        |> json(%{error: "Erro no download. Código de saída: #{exit_code}"})
    end
  end
end

defmodule VideoDownloaderElixirWeb.Controllers.ThumbnailProxyController do
  use VideoDownloaderElixirWeb, :controller

  @moduledoc """
  Proxy controller para servir thumbnails de URLs externas (Facebook, Instagram, etc)
  Evita problemas de CORS e políticas de hotlinking
  """

  def show(conn, %{"url" => encoded_url}) do
    IO.inspect(encoded_url, label: "📸 Encoded URL recebida")

    case Base.url_decode64(encoded_url, padding: false) do
      {:ok, url} ->
        IO.inspect(url, label: "📸 URL decodificada")

        case fetch_image(url) do
          {:ok, image_data, content_type} ->
            IO.puts("✅ Imagem baixada com sucesso: #{byte_size(image_data)} bytes")
            conn
            |> put_resp_content_type(content_type)
            |> put_resp_header("cache-control", "public, max-age=86400")
            |> send_resp(200, image_data)

          {:error, reason} ->
            IO.inspect(reason, label: "❌ Erro ao baixar imagem")
            send_resp(conn, 404, "Image not found")
        end

      :error ->
        IO.puts("❌ Erro ao decodificar URL")
        send_resp(conn, 400, "Invalid URL")
    end
  end

  defp fetch_image(url) do
    IO.puts("🔄 Fazendo requisição HTTP para: #{url}")

    case Req.get(url,
      headers: [
        {"user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"},
        {"accept", "image/*,*/*"},
        {"accept-language", "en-US,en;q=0.9"},
        {"referer", "https://www.facebook.com/"}
      ],
      redirect: true,
      max_redirects: 5
    ) do
      {:ok, %{status: 200, body: body, headers: headers}} ->
        content_type = get_content_type_from_req(headers)
        IO.puts("✅ Requisição bem-sucedida: #{content_type}, #{byte_size(body)} bytes")
        {:ok, body, content_type}

      {:ok, %{status: status}} ->
        IO.puts("❌ Status HTTP: #{status}")
        {:error, {:http_status, status}}

      {:error, reason} ->
        IO.inspect(reason, label: "❌ Erro na requisição HTTP")
        {:error, reason}
    end
  end

  defp get_content_type_from_req(headers) do
    case Enum.find(headers, fn {key, _} -> String.downcase(key) == "content-type" end) do
      {_, [value | _]} -> value
      {_, value} when is_binary(value) -> value
      nil -> "image/jpeg"
    end
  end
end

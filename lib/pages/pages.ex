defmodule VideoDownloaderElixirWeb.Pages do
  @moduledoc """
  Todas as páginas da aplicação.
  Similar ao App.jsx do React - extremamente limpo e simples.
  """

  # ===== PÁGINAS DA APLICAÇÃO =====
  # Cada página é apenas 4 linhas - super limpo!

  defmodule Home do
    @moduledoc "Página inicial do Video Downloader"
    use VideoDownloaderElixirWeb, :page
  end

  defmodule Contatos do
    @moduledoc "Página de contatos e informações"
    use VideoDownloaderElixirWeb, :page
  end

  defmodule Downloader do
    @moduledoc "Página de download de vídeos/músicas"
    use VideoDownloaderElixirWeb, :page
  end

  # Adicionar páginas é SUPER simples - apenas 3 linhas:
  #
  # defmodule About do
  #   @moduledoc "Página sobre nós"
  #   use VideoDownloaderElixirWeb, :page
  # end
  #
  # defmodule Profile do
  #   @moduledoc "Página de perfil"
  #   use VideoDownloaderElixirWeb, :page
  # end
  #
  # Para usar pasta customizada:
  # defmodule Settings do
  #   @moduledoc "Configurações"
  #   use VideoDownloaderElixirWeb, {:page, folder: "config"}
  # end
end

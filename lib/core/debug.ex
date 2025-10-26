defmodule VideoDownloaderElixir.Core.Debug do
  @moduledoc """
  Helper para gerenciar logs de debug baseado na variável DEBUG_LOGS do .env
  """
  require Logger

  @doc """
  Retorna true se os logs de debug estão habilitados
  """
  def enabled? do
    Application.get_env(:video_downloader_elixir, :debug_logs, false)
  end

  @doc """
  Loga uma mensagem apenas se DEBUG_LOGS=true
  """
  def log(level \\ :info, message) do
    if enabled?() do
      case level do
        :debug -> Logger.debug(message)
        :info -> Logger.info(message)
        :warn -> Logger.warning(message)
        :error -> Logger.error(message)
        _ -> Logger.info(message)
      end
    end
  end

  @doc """
  Versão macro para usar com require
  """
  defmacro debug_log(level, message) do
    quote do
      if VideoDownloaderElixir.Core.Debug.enabled?() do
        require Logger
        case unquote(level) do
          :debug -> Logger.debug(unquote(message))
          :info -> Logger.info(unquote(message))
          :warn -> Logger.warning(unquote(message))
          :error -> Logger.error(unquote(message))
          _ -> Logger.info(unquote(message))
        end
      end
    end
  end
end

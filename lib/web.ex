defmodule VideoDownloaderElixir do
  @moduledoc """
  VideoDownloaderElixir - Template Phoenix com DaisyUI

  Estrutura organizada similar ao Laravel:
  - lib/controllers/ - Controllers da aplicação
  - lib/pages/ - Pages e templates
  - lib/models/ - Models e esquemas
  - lib/components/ - Componentes reutilizáveis
  - lib/core/ - Arquivos core (Application, Router, Endpoint, etc.)
  """
end

defmodule VideoDownloaderElixirWeb do
  @moduledoc """
  Template Phoenix + DaisyUI

  Estrutura simplificada:
  - lib/controllers/ - Controllers
  - lib/pages/ - Pages e templates
  - lib/components/ - Componentes reutilizáveis
  - lib/layouts/ - Layouts da aplicação
  - lib/core/ - Arquivos core (Application, Router, Endpoint, etc.)
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: VideoDownloaderElixirWeb.Layouts]

      use Gettext, backend: VideoDownloaderElixirWeb.Core.Gettext
      import Plug.Conn
      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {VideoDownloaderElixirWeb.Layouts, :app}
      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component
      import Phoenix.Controller, only: [get_csrf_token: 0, view_module: 1, view_template: 1]
      unquote(html_helpers())
    end
  end

  def page do
    quote do
      use VideoDownloaderElixirWeb, :html

      # Se não especificar folder, usa o nome do módulo em minúsculo
      @folder Module.split(__MODULE__) |> List.last() |> String.downcase()

      embed_templates @folder <> "/*"
    end
  end

  defp html_helpers do
    quote do
      use Gettext, backend: VideoDownloaderElixirWeb.Core.Gettext
      import Phoenix.HTML
      import VideoDownloaderElixirWeb.Components.CoreComponents
      alias Phoenix.LiveView.JS
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: VideoDownloaderElixirWeb.Core.Endpoint,
        router: VideoDownloaderElixirWeb.Core.Router,
        statics: VideoDownloaderElixirWeb.static_paths()
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__({which, opts}) when is_atom(which) do
    case which do
      :page ->
        folder = Keyword.get(opts, :folder, nil)

        quote do
          use VideoDownloaderElixirWeb, :html

          # Se não especificar folder, usa o nome do módulo em minúsculo
          @folder unquote(folder) ||
            (__MODULE__
             |> Module.split()
             |> List.last()
             |> String.downcase())

          embed_templates @folder <> "/*"
        end

      _ ->
        apply(__MODULE__, which, [])
    end
  end
end

defmodule VideoDownloaderElixirWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use VideoDownloaderElixirWeb, :controller` and
  `use VideoDownloaderElixirWeb, :live_view`.
  """
  use VideoDownloaderElixirWeb, :html

  embed_templates "layouts/*"
end

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Phoenix LiveView web app for downloading videos from YouTube, Facebook, and Instagram. Uses `yt-dlp` + `ffmpeg` under the hood. Users enter a URL, select a resolution/format, and download.

## Commands

```bash
# Install dependencies and build assets
mix setup

# Start dev server (http://localhost:4000)
mix phx.server

# With debug logging enabled
DEBUG_LOGS=true mix phx.server

# Build assets
mix assets.build

# Build and minify for production
mix assets.deploy

# Format code
mix format
```

**System requirements:** `yt-dlp` and `ffmpeg` must be installed on the host.

## Architecture

The project structure is intentionally inspired by React (componentization) and Laravel (folder organization):

```
lib/
├── core/          — Phoenix internals (Application, Router, Endpoint, Gettext, Debug)
├── controllers/   — HTTP controllers (REST API endpoints; must end with _controller)
├── pages/         — LiveView pages (each page in its own subfolder with .heex template)
├── components/    — Reusable UI components (DaisyUI-based)
├── layouts/       — Global HTML layouts
└── web.ex         — Central macro definitions shared across the app
```

**Key data flow:**
1. User submits URL → `DownloaderLive` sends `fetch_resolutions` event
2. `MetadataCache` (GenServer) checks 30-min in-memory cache; on miss, delegates to `MetadataService` (wraps `yt-dlp --dump-json`)
3. Results broadcast via PubSub; LiveView updates with available formats
4. User picks format → `DownloadProgress` triggers async `yt-dlp` download
5. File served via `DownloaderController` at `/api/download`, then deleted from `/tmp/`

**Other controllers:**
- `ThumbnailProxyController` — proxies thumbnail images at `/api/thumbnail/:url` (avoids CORS/hotlink issues)

## Creating Pages

Never create page files manually. Always follow this pattern:

1. Create `lib/pages/PAGE_NAME/` folder with a `.heex` template inside
2. Register the page in `lib/pages/pages.ex`:

```elixir
defmodule MyPage do
  @moduledoc "Description"
  use VideoDownloaderElixirWeb, :page
end

# With a custom folder name:
defmodule Settings do
  @moduledoc "Settings"
  use VideoDownloaderElixirWeb, {:page, folder: "config"}
end
```

## UI Components

All UI must use **DaisyUI** components. Add reusable components to `lib/components/`. Compose from DaisyUI primitives; do not hand-roll styles when a DaisyUI component exists.

## Configuration

Copy `.env.example` to `.env` before running locally. Key variables:

| Variable | Purpose |
|---|---|
| `DEBUG_LOGS` | `true`/`false` — enables `Debug.log/2` output |
| `PHX_HOST` | Required in production |
| `SECRET_KEY_BASE` | Generate with `mix phx.gen.secret` |
| `PORT` | HTTP port (default 4000) |

Config files: `config/config.exs` (base), `config/dev.exs`, `config/runtime.exs` (prod secrets), `config/test.exs`.

## Debug Logging

Use `VideoDownloaderElixir.Debug.log/2` instead of `IO.inspect` or `Logger.debug`. It respects the `DEBUG_LOGS` env var so logs are silent in prod without code changes.

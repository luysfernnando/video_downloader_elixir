# ================================
# Build Stage - Compilação
# ================================
FROM hexpm/elixir:1.17.3-erlang-27.1.2-alpine-3.20.3 AS builder

# Instalar dependências do sistema necessárias para build
RUN apk add --no-cache \
    build-base \
    git \
    nodejs \
    npm

# Criar diretório da aplicação
WORKDIR /app

# Configurar ambiente de produção
ENV MIX_ENV=prod

# Instalar Hex e Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copiar arquivos de dependências
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copiar arquivos de assets
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

# Copiar código da aplicação
COPY priv priv
COPY assets assets
COPY config config
COPY lib lib

# Compilar assets
RUN mix assets.deploy

# Compilar o release
RUN mix do compile, release

# ================================
# Runtime Stage - Produção
# ================================
FROM alpine:3.20.3 AS runtime

# Instalar dependências runtime mínimas
RUN apk add --no-cache \
    libstdc++ \
    openssl \
    ncurses-libs

# Criar usuário não-root para segurança
RUN addgroup -g 1000 elixir && \
    adduser -D -u 1000 -G elixir elixir

# Criar diretório da aplicação
WORKDIR /app

# Copiar o release do stage de build
COPY --from=builder --chown=elixir:elixir /app/_build/prod/rel/video_downloader_elixir ./

# Trocar para usuário não-root
USER elixir

# Expor porta padrão
EXPOSE 4000

# Variáveis de ambiente padrão
ENV PHX_SERVER=true \
    MIX_ENV=prod \
    PORT=4000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/ || exit 1

# Comando de inicialização
CMD ["bin/video_downloader_elixir", "start"]

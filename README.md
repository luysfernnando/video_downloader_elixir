# VideoDownloaderElixir

## Como rodar o projeto

```bash
# Instalar dependências do sistema (Arch Linux)
sudo pacman -S yt-dlp ffmpeg

# Instalar dependências do projeto
mix deps.get
cd assets && npm install

# Configurar variáveis de ambiente (opcional)
cp .env.example .env
# Edite o arquivo .env para alterar DEBUG_LOGS=true/false

# Iniciar o servidor
mix phx.server
```

Acesse [`localhost:4000`](http://localhost:4000)

## Configuração

### Debug Logs

Para habilitar/desabilitar logs de debug, edite o arquivo `.env`:

```bash
# Habilitar logs de debug
DEBUG_LOGS=true

# Desabilitar logs de debug
DEBUG_LOGS=false
```

Reinicie o servidor após alterar as configurações.

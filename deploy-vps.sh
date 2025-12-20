# ============================================
# Script rápido para deploy na VPS
# ============================================
# Execute este script na VPS após configurar o .env

#!/bin/bash

set -e

echo "🚀 Iniciando deploy do Video Downloader..."

# Carregar variáveis de ambiente
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ Arquivo .env não encontrado!"
    echo "Crie um arquivo .env baseado no .env.example"
    exit 1
fi

# Validar variáveis obrigatórias
if [ -z "$DOCKER_USERNAME" ] || [ -z "$SECRET_KEY_BASE" ]; then
    echo "❌ Variáveis obrigatórias não configuradas!"
    echo "Configure DOCKER_USERNAME e SECRET_KEY_BASE no arquivo .env"
    exit 1
fi

echo "✅ Variáveis de ambiente carregadas"

# Fazer pull da última versão
echo "📦 Baixando última versão da imagem..."
docker-compose pull

# Parar containers antigos
echo "⏸️  Parando containers antigos..."
docker-compose down

# Iniciar aplicação
echo "▶️  Iniciando aplicação..."
docker-compose up -d

# Aguardar inicialização
echo "⏳ Aguardando aplicação iniciar..."
sleep 10

# Verificar status
echo ""
echo "📊 Status dos containers:"
docker-compose ps

echo ""
echo "✅ Deploy concluído!"
echo ""
echo "🌐 Aplicação disponível em: http://localhost:${APP_PORT:-4000}"
echo ""
echo "Para ver os logs: docker-compose logs -f"

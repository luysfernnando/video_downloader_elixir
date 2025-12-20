#!/bin/bash

# ============================================================================
# Script de Build e Deploy Automatizado
# ============================================================================
# Este script:
# 1. Faz build da aplicação
# 2. Executa testes funcionais
# 3. Cria imagem Docker otimizada
# 4. Publica no Docker Hub
# ============================================================================

set -e  # Para execução em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Banner
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║       Video Downloader - Build & Deploy Automation        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================================
# 1. Validar requisitos
# ============================================================================
log_info "Validando requisitos..."

if ! command -v docker &> /dev/null; then
    log_error "Docker não está instalado"
    exit 1
fi

if ! command -v mix &> /dev/null; then
    log_error "Elixir/Mix não está instalado"
    exit 1
fi

log_success "Requisitos validados"

# ============================================================================
# 2. Configurar variáveis
# ============================================================================
log_info "Configurando variáveis..."

# Versão da aplicação (pega do mix.exs ou usa variável de ambiente)
VERSION=${VERSION:-$(grep 'version:' mix.exs | sed -E 's/.*version: "(.*)".*/\1/')}
DOCKER_USERNAME=${DOCKER_USERNAME:-""}
IMAGE_NAME="video-downloader-elixir"
FULL_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}"
LATEST_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}:latest"

# Validar Docker username
if [ -z "$DOCKER_USERNAME" ]; then
    log_error "DOCKER_USERNAME não está definido"
    log_info "Configure com: export DOCKER_USERNAME=seu-usuario"
    exit 1
fi

log_success "Versão: ${VERSION}"
log_success "Imagem: ${FULL_IMAGE_NAME}"

# ============================================================================
# 3. Limpar build anterior
# ============================================================================
log_info "Limpando builds anteriores..."
mix clean
rm -rf _build/prod
log_success "Limpeza concluída"

# ============================================================================
# 4. Instalar dependências
# ============================================================================
log_info "Instalando dependências..."
mix deps.get --only prod
log_success "Dependências instaladas"

# ============================================================================
# 5. Executar testes (opcional, mas recomendado)
# ============================================================================
if [ "${SKIP_TESTS}" != "true" ]; then
    log_info "Executando testes..."
    
    if mix test; then
        log_success "Todos os testes passaram"
    else
        log_error "Testes falharam"
        exit 1
    fi
else
    log_warning "Testes ignorados (SKIP_TESTS=true)"
fi

# ============================================================================
# 6. Build da imagem Docker
# ============================================================================
log_info "Construindo imagem Docker..."
log_info "Isso pode levar alguns minutos..."

if docker build \
    --build-arg MIX_ENV=prod \
    --tag "${FULL_IMAGE_NAME}" \
    --tag "${LATEST_IMAGE_NAME}" \
    .; then
    log_success "Imagem Docker construída com sucesso"
else
    log_error "Falha ao construir imagem Docker"
    exit 1
fi

# ============================================================================
# 7. Testar imagem Docker localmente
# ============================================================================
log_info "Testando imagem Docker localmente..."

# Gerar SECRET_KEY_BASE temporário para teste
TEST_SECRET=$(mix phx.gen.secret)

# Iniciar container temporário
CONTAINER_ID=$(docker run -d \
    -e SECRET_KEY_BASE="${TEST_SECRET}" \
    -e PHX_HOST=localhost \
    -p 4001:4000 \
    "${FULL_IMAGE_NAME}")

log_info "Container de teste iniciado: ${CONTAINER_ID:0:12}"

# Aguardar aplicação iniciar
log_info "Aguardando aplicação iniciar..."
sleep 10

# Testar se aplicação responde
if curl -f http://localhost:4001/ > /dev/null 2>&1; then
    log_success "Aplicação está respondendo corretamente"
    TESTS_PASSED=true
else
    log_error "Aplicação não está respondendo"
    log_info "Logs do container:"
    docker logs "${CONTAINER_ID}"
    TESTS_PASSED=false
fi

# Parar e remover container de teste
log_info "Parando container de teste..."
docker stop "${CONTAINER_ID}" > /dev/null
docker rm "${CONTAINER_ID}" > /dev/null

if [ "${TESTS_PASSED}" != "true" ]; then
    log_error "Testes funcionais falharam"
    exit 1
fi

log_success "Testes funcionais passaram"

# ============================================================================
# 8. Fazer login no Docker Hub
# ============================================================================
if [ "${SKIP_PUSH}" != "true" ]; then
    log_info "Fazendo login no Docker Hub..."
    
    if [ -n "${DOCKER_PASSWORD}" ]; then
        echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
    else
        docker login -u "${DOCKER_USERNAME}"
    fi
    
    log_success "Login realizado com sucesso"
    
    # ========================================================================
    # 9. Publicar imagem no Docker Hub
    # ========================================================================
    log_info "Publicando imagem no Docker Hub..."
    
    docker push "${FULL_IMAGE_NAME}"
    docker push "${LATEST_IMAGE_NAME}"
    
    log_success "Imagem publicada com sucesso"
else
    log_warning "Push ignorado (SKIP_PUSH=true)"
fi

# ============================================================================
# 10. Informações finais
# ============================================================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║               Build Concluído com Sucesso!                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
log_success "Imagem: ${FULL_IMAGE_NAME}"
log_success "Latest: ${LATEST_IMAGE_NAME}"
echo ""
log_info "Para fazer deploy na VPS, execute:"
echo -e "${BLUE}  docker pull ${FULL_IMAGE_NAME}${NC}"
echo -e "${BLUE}  docker-compose up -d${NC}"
echo ""

# Exibir tamanho da imagem
IMAGE_SIZE=$(docker images "${FULL_IMAGE_NAME}" --format "{{.Size}}")
log_info "Tamanho da imagem: ${IMAGE_SIZE}"

exit 0

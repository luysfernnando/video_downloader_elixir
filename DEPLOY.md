# 🚀 Guia de Deploy - AWS VPS Ubuntu com Docker

Este guia detalha como fazer deploy da aplicação Video Downloader Elixir em uma VPS AWS Ubuntu com recursos limitados (1 core, 1GB RAM) usando Docker.

## 📋 Pré-requisitos

### Na sua máquina local:
- Docker instalado
- Elixir e Mix instalados
- Conta no Docker Hub

### Na VPS AWS:
- Ubuntu (recomendado: 20.04 LTS ou superior)
- Docker e Docker Compose instalados
- Porta 4000 liberada no Security Group da AWS

---

## 🛠️ Configuração Inicial

### 1. Preparar VPS

SSH na sua VPS:
```bash
ssh ubuntu@seu-ip-da-vps
```

Instalar Docker:
```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER
newgrp docker

# Instalar Docker Compose
sudo apt install docker-compose -y

# Verificar instalação
docker --version
docker-compose --version
```

### 2. Configurar variáveis de ambiente na VPS

Criar arquivo `.env` na VPS:
```bash
mkdir -p ~/video-downloader
cd ~/video-downloader
nano .env
```

Adicionar as seguintes variáveis:
```env
# Configurações do Docker
DOCKER_USERNAME=seu-usuario-dockerhub
VERSION=latest
APP_PORT=4000

# Configurações da aplicação
PHX_HOST=seu-dominio.com  # ou IP da VPS
SECRET_KEY_BASE=sua-secret-key-aqui

# Otimizações de memória
ERL_MAX_PORTS=4096
```

Para gerar o `SECRET_KEY_BASE`, execute localmente:
```bash
mix phx.gen.secret
```

---

## 📦 Build e Deploy Automatizado

### Passo 1: Configurar credenciais do Docker Hub (local)

```bash
export DOCKER_USERNAME=seu-usuario-dockerhub
export DOCKER_PASSWORD=sua-senha-dockerhub  # Opcional, será solicitado se não definido
```

### Passo 2: Executar o script de build

```bash
./build-and-deploy.sh
```

O script irá:
1. ✅ Validar requisitos
2. ✅ Limpar builds anteriores
3. ✅ Instalar dependências
4. ✅ Executar testes
5. ✅ Construir imagem Docker otimizada
6. ✅ Testar a imagem localmente
7. ✅ Fazer login no Docker Hub
8. ✅ Publicar imagem no Docker Hub

### Passo 3: Fazer deploy na VPS

SSH na VPS e executar:
```bash
cd ~/video-downloader

# Baixar docker-compose.yml
wget https://raw.githubusercontent.com/seu-usuario/video-downloader-elixir/main/docker-compose.yml

# Ou copiar manualmente o arquivo docker-compose.yml para a VPS

# Fazer pull da imagem
docker pull ${DOCKER_USERNAME}/video-downloader-elixir:latest

# Iniciar aplicação
docker-compose up -d

# Verificar status
docker-compose ps
docker-compose logs -f
```

---

## 🔧 Comandos Úteis

### Gerenciamento da aplicação

```bash
# Ver logs
docker-compose logs -f

# Ver logs apenas da última hora
docker-compose logs --since 1h

# Parar aplicação
docker-compose down

# Reiniciar aplicação
docker-compose restart

# Ver uso de recursos
docker stats

# Ver informações do container
docker inspect video_downloader
```

### Atualizações

Para atualizar a aplicação:
```bash
# Na máquina local: fazer novo build e push
./build-and-deploy.sh

# Na VPS: atualizar container
cd ~/video-downloader
docker-compose pull
docker-compose up -d
```

### Limpeza

```bash
# Remover containers parados
docker container prune -f

# Remover imagens não utilizadas
docker image prune -a -f

# Remover tudo não utilizado
docker system prune -a -f --volumes
```

---

## 🎯 Otimizações para VPS de 1GB RAM

A configuração já inclui várias otimizações:

### 1. Limites de recursos no Docker Compose
- **Memória máxima**: 512MB para a aplicação
- **Memória reservada**: 256MB garantidos
- **CPU**: 1 core completo disponível

### 2. Imagem Docker otimizada
- Base Alpine Linux (muito menor)
- Multi-stage build (apenas runtime na imagem final)
- Sem ferramentas de desenvolvimento

### 3. Configurações da BEAM/Erlang
```env
ERL_MAX_PORTS=4096  # Reduz uso de memória
ELIXIR_ERL_OPTIONS="+sbwt none +sbwtdcpu none +sbwtdio none"
```

### 4. Logs controlados
- Máximo de 10MB por arquivo
- Máximo de 3 arquivos de log
- Rotação automática

---

## 🔒 Segurança

### Configurar firewall (UFW)

```bash
# Ativar firewall
sudo ufw enable

# Permitir SSH
sudo ufw allow 22/tcp

# Permitir porta da aplicação
sudo ufw allow 4000/tcp

# Verificar status
sudo ufw status
```

### HTTPS com Nginx (Opcional)

Para produção, recomenda-se usar Nginx como reverse proxy com SSL:

```bash
# Instalar Nginx e Certbot
sudo apt install nginx certbot python3-certbot-nginx -y

# Configurar Nginx
sudo nano /etc/nginx/sites-available/video-downloader

# Adicionar configuração:
```

```nginx
server {
    listen 80;
    server_name seu-dominio.com;

    location / {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Ativar site
sudo ln -s /etc/nginx/sites-available/video-downloader /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Obter certificado SSL
sudo certbot --nginx -d seu-dominio.com
```

---

## 📊 Monitoramento

### Health Check

A aplicação inclui health check automático. Para verificar:

```bash
# Via Docker
docker inspect video_downloader | grep -A 10 Health

# Via curl
curl http://localhost:4000/
```

### Monitoramento de recursos

```bash
# Uso de memória e CPU em tempo real
docker stats video_downloader

# Logs do sistema
journalctl -u docker -f
```

---

## 🐛 Troubleshooting

### Aplicação não inicia

```bash
# Verificar logs
docker-compose logs

# Verificar variáveis de ambiente
docker-compose config

# Verificar se a porta está em uso
sudo netstat -tulpn | grep 4000
```

### Erro de memória insuficiente

```bash
# Verificar uso de memória do sistema
free -h

# Adicionar swap (temporário)
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Container reiniciando constantemente

```bash
# Ver logs detalhados
docker logs video_downloader --tail 100

# Verificar health check
docker inspect video_downloader | grep -A 10 Health
```

---

## 📝 Variáveis de Ambiente

| Variável | Descrição | Obrigatório | Padrão |
|----------|-----------|-------------|--------|
| `DOCKER_USERNAME` | Usuário do Docker Hub | ✅ | - |
| `VERSION` | Versão da imagem | ❌ | `latest` |
| `PHX_HOST` | Host/domínio da aplicação | ✅ | `localhost` |
| `SECRET_KEY_BASE` | Secret key do Phoenix | ✅ | - |
| `PORT` | Porta da aplicação | ❌ | `4000` |
| `APP_PORT` | Porta exposta no host | ❌ | `4000` |
| `MIX_ENV` | Ambiente Elixir | ❌ | `prod` |

---

## 🚀 Scripts Disponíveis

### Build local sem deploy
```bash
SKIP_PUSH=true ./build-and-deploy.sh
```

### Build sem executar testes
```bash
SKIP_TESTS=true ./build-and-deploy.sh
```

### Build com versão específica
```bash
VERSION=1.0.0 ./build-and-deploy.sh
```

---

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique os logs: `docker-compose logs -f`
2. Consulte a documentação do Phoenix: https://phoenixframework.org/
3. Verifique issues no repositório

---

## 📄 Licença

Este projeto está sob a licença especificada no arquivo LICENSE.md

#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# NOFX 服务器快速部署脚本（镜像仓库方式）
# 使用方法：复制此脚本到服务器运行
# ═══════════════════════════════════════════════════════════════

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   NOFX 服务器部署脚本（镜像仓库方式）      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# 部署目录
DEPLOY_DIR="/root/NOFX_Deploy"

echo -e "${BLUE}📂 创建部署目录...${NC}"
mkdir -p $DEPLOY_DIR
cd $DEPLOY_DIR

echo -e "${BLUE}📁 创建子目录...${NC}"
mkdir -p decision_logs prompts secrets

echo -e "${BLUE}🔐 生成RSA密钥...${NC}"
if [ ! -f "secrets/rsa_key" ]; then
    ssh-keygen -t rsa -b 2048 -f secrets/rsa_key -N ""
    chmod 600 secrets/rsa_key
    chmod 644 secrets/rsa_key.pub
    echo -e "${GREEN}✅ RSA密钥已生成${NC}"
else
    echo -e "${YELLOW}⚠️  RSA密钥已存在，跳过${NC}"
fi

echo -e "${BLUE}🔑 生成加密密钥...${NC}"
DATA_KEY=$(openssl rand -base64 32)
JWT_KEY=$(openssl rand -base64 32)

echo -e "${BLUE}📝 创建.env文件...${NC}"
cat > .env << EOF
# 端口配置
NOFX_BACKEND_PORT=8080
NOFX_FRONTEND_PORT=3000

# 时区设置
NOFX_TIMEZONE=Asia/Shanghai

# 数据加密密钥
DATA_ENCRYPTION_KEY=$DATA_KEY

# JWT认证密钥
JWT_SECRET=$JWT_KEY
EOF
chmod 600 .env
echo -e "${GREEN}✅ .env文件已创建${NC}"

echo -e "${BLUE}📝 创建config.json...${NC}"
cat > config.json << 'EOF'
{
  "leverage_size": 5,
  "open_coins": ["BTC", "ETH"],
  "admin_mode": false
}
EOF
echo -e "${GREEN}✅ config.json已创建${NC}"

echo -e "${BLUE}📝 创建数据库文件...${NC}"
touch config.db
chmod 600 config.db
echo -e "${GREEN}✅ 数据库文件已创建${NC}"

echo -e "${BLUE}📝 创建docker-compose.prod.yml...${NC}"
cat > docker-compose.prod.yml << 'EOF'
services:
  # Backend service
  nofx:
    image: ghcr.io/otherwow/nofx_cloned/backend:latest
    container_name: nofx-trading
    restart: unless-stopped
    stop_grace_period: 30s
    ports:
      - "${NOFX_BACKEND_PORT:-8080}:8080"
    volumes:
      - ./config.json:/app/config.json:ro
      - ./config.db:/app/config.db
      - ./decision_logs:/app/decision_logs
      - ./prompts:/app/prompts
      - ./secrets:/app/secrets:ro
      - /etc/localtime:/etc/localtime:ro
    environment:
      - TZ=${NOFX_TIMEZONE:-Asia/Shanghai}
      - AI_MAX_TOKENS=4000
      - DATA_ENCRYPTION_KEY=${DATA_ENCRYPTION_KEY}
      - JWT_SECRET=${JWT_SECRET}
    networks:
      - nofx-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # Frontend service
  nofx-frontend:
    image: ghcr.io/otherwow/nofx_cloned/frontend:latest
    container_name: nofx-frontend
    restart: unless-stopped
    ports:
      - "${NOFX_FRONTEND_PORT:-3000}:80"
    networks:
      - nofx-network
    depends_on:
      - nofx
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://127.0.0.1/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 5s

networks:
  nofx-network:
    driver: bridge
EOF
echo -e "${GREEN}✅ docker-compose.prod.yml已创建${NC}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          部署环境准备完成！                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📋 部署目录：${NC}$DEPLOY_DIR"
echo -e "${BLUE}📋 已创建的文件：${NC}"
echo "   ✅ .env (环境变量)"
echo "   ✅ config.json (配置文件)"
echo "   ✅ config.db (数据库)"
echo "   ✅ docker-compose.prod.yml (Docker编排)"
echo "   ✅ secrets/rsa_key (RSA密钥)"
echo ""
echo -e "${YELLOW}⚠️  请在GitHub配置以下Secret：${NC}"
echo "   PROJECT_PATH = $DEPLOY_DIR"
echo ""
echo -e "${BLUE}🚀 首次启动命令：${NC}"
echo "   cd $DEPLOY_DIR"
echo "   docker pull ghcr.io/otherwow/nofx_cloned/backend:latest"
echo "   docker pull ghcr.io/otherwow/nofx_cloned/frontend:latest"
echo "   docker-compose -f docker-compose.prod.yml up -d"
echo ""
echo -e "${BLUE}📊 查看日志：${NC}"
echo "   docker-compose -f docker-compose.prod.yml logs -f"
echo ""

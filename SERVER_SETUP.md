# 🚀 服务器部署指南（镜像仓库方式）

## 📋 服务器只需要这些文件（不需要完整代码）

```
/root/NOFX_Deploy/          # 部署目录
├── docker-compose.prod.yml  # Docker编排文件
├── .env                     # 环境变量
├── config.json              # 基础配置
├── config.db                # 数据库（自动创建）
├── beta_codes.txt           # Beta码（可选）
├── decision_logs/           # 日志目录
├── prompts/                 # 提示词目录
└── secrets/                 # 密钥目录
    ├── rsa_key
    └── rsa_key.pub
```

## 🛠️ 服务器首次部署步骤

### 1. 创建部署目录

```bash
# 创建部署目录
mkdir -p /root/NOFX_Deploy
cd /root/NOFX_Deploy

# 创建必要的子目录
mkdir -p decision_logs prompts secrets
```

### 2. 创建配置文件

#### 创建 .env 文件

```bash
cat > .env << 'EOF'
# 端口配置
NOFX_BACKEND_PORT=8080
NOFX_FRONTEND_PORT=3000

# 时区设置
NOFX_TIMEZONE=Asia/Shanghai

# 数据加密密钥（生成随机密钥）
DATA_ENCRYPTION_KEY=your-32-char-encryption-key-here

# JWT认证密钥（生成随机密钥）
JWT_SECRET=your-jwt-secret-key-here
EOF

# 生成随机密钥
echo "DATA_ENCRYPTION_KEY=$(openssl rand -base64 32)" >> .env
echo "JWT_SECRET=$(openssl rand -base64 32)" >> .env
```

#### 创建 config.json 文件

```bash
cat > config.json << 'EOF'
{
  "leverage_size": 5,
  "open_coins": ["BTC", "ETH"],
  "admin_mode": false,
  "jwt_secret": "your-jwt-secret"
}
EOF
```

#### 创建数据库文件

```bash
# 创建空数据库文件
touch config.db
chmod 600 config.db
```

#### 生成RSA密钥

```bash
# 生成RSA密钥对
ssh-keygen -t rsa -b 2048 -f secrets/rsa_key -N ""
chmod 600 secrets/rsa_key
chmod 644 secrets/rsa_key.pub
```

### 3. 上传 docker-compose.prod.yml

将本地的 `docker-compose.prod.yml` 复制到服务器：

```bash
# 在本地执行（或手动复制）
scp docker-compose.prod.yml root@your-server:/root/NOFX_Deploy/
```

或者直接在服务器创建：

```bash
cat > docker-compose.prod.yml << 'EOF'
# 将 docker-compose.prod.yml 的内容粘贴到这里
EOF
```

### 4. 登录GitHub Container Registry

服务器需要有权限拉取镜像（公开镜像不需要）：

```bash
# 如果镜像设为私有，需要登录
docker login ghcr.io -u YourGitHubUsername
# 输入GitHub Personal Access Token（需要有packages:read权限）
```

### 5. 首次启动

```bash
cd /root/NOFX_Deploy

# 拉取镜像
docker pull ghcr.io/otherwow/nofx_cloned/backend:latest
docker pull ghcr.io/otherwow/nofx_cloned/frontend:latest

# 启动服务
docker-compose -f docker-compose.prod.yml up -d

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f
```

## 🔄 后续自动部署

配置完成后，每次你在本地 `git push`：
1. GitHub Actions会自动构建新镜像
2. 推送到GitHub Container Registry
3. SSH到服务器
4. 自动拉取最新镜像
5. 重启容器

**完全自动化，无需手动操作！**

## 📊 常用命令

```bash
# 查看服务状态
docker ps

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f

# 重启服务
docker-compose -f docker-compose.prod.yml restart

# 停止服务
docker-compose -f docker-compose.prod.yml down

# 更新镜像
docker pull ghcr.io/otherwow/nofx_cloned/backend:latest
docker pull ghcr.io/otherwow/nofx_cloned/frontend:latest
docker-compose -f docker-compose.prod.yml up -d
```

## 🔍 故障排查

### 镜像拉取失败

```bash
# 检查是否登录
docker login ghcr.io

# 手动拉取测试
docker pull ghcr.io/otherwow/nofx_cloned/backend:latest
```

### 容器启动失败

```bash
# 查看详细日志
docker logs nofx-trading
docker logs nofx-frontend
```

### 端口被占用

```bash
# 修改 .env 中的端口
nano .env
# 然后重启
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```

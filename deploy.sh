#!/bin/bash
# ============================================================
# 邻里 - 云端部署脚本 (Ubuntu 22.04)
# 在服务器上执行: bash /tmp/deploy-neighbor.sh
# ============================================================

set -e

DOMAIN="harmonycare.cn"
APP_DIR="/opt/neighbor"
LOG_DIR="/var/log/neighbor"

echo "=========================================="
echo "  邻里系统 - 云端部署脚本"
echo "=========================================="

# 1. 安装依赖
echo "[1/6] 安装系统依赖..."
apt-get update -qq
apt-get install -y -qq python3 python3-pip python3-venv nginx sqlite3 curl
pip3 install -q fastapi uvicorn[standard] sqlalchemy pydantic pydantic-settings \
    python-jose bcrypt python-multipart httpx python-dotenv email-validator

# 2. 创建目录
echo "[2/6] 创建目录..."
mkdir -p "$APP_DIR/backend"
mkdir -p "$APP_DIR/web"
mkdir -p "$LOG_DIR"
mkdir -p "$APP_DIR/uploads"

# 3. 配置后端
echo "[3/6] 配置后端..."
cat > "$APP_DIR/backend/.env" << ENVEOF
DATABASE_URL=sqlite+pysqlite:///$APP_DIR/backend/neighbor.db
SECRET_KEY=neighbor-prod-$(openssl rand -hex 32)
DASHSCOPE_API_KEY=${DASHSCOPE_API_KEY:-}
QWEN_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
QWEN_MODEL_DEFAULT=qwen-plus
QWEN_MODEL_REVIEW=qwen-plus
QWEN_MODEL_SUMMARY=qwen-flash
QWEN_TIMEOUT=30
QWEN_MAX_RETRIES=3
UPLOAD_DIR=$APP_DIR/uploads
MAX_UPLOAD_SIZE=10485760
CORS_ORIGINS=["https://$DOMAIN"]
LOG_LEVEL=INFO
ENVEOF

# 4. 配置 Nginx
echo "[4/6] 配置 Nginx..."
cat > /etc/nginx/sites-available/neighbor << NGINXEOF
server {
    listen 80;
    server_name $DOMAIN;

    # Web 前端静态文件
    location / {
        root $APP_DIR/web;
        try_files \$uri \$uri/ /index.html;
        gzip_static on;
        expires 1d;
        add_header Cache-Control "public, no-transform";
    }

    # API 反向代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 30s;
        proxy_read_timeout 60s;
    }

    # 访问日志
    access_log $LOG_DIR/access.log;
    error_log $LOG_DIR/error.log;
}
NGINXEOF

ln -sf /etc/nginx/sites-available/neighbor /etc/nginx/sites-enabled/neighbor
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# 5. 配置 systemd 服务
echo "[5/6] 配置 systemd 服务..."
cat > /etc/systemd/system/neighbor-backend.service << SVCEOF
[Unit]
Description=邻里后端服务
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=$APP_DIR/backend
Environment=PATH=$APP_DIR/backend/venv/bin
EnvironmentFile=$APP_DIR/backend/.env
ExecStart=$APP_DIR/backend/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 4
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable neighbor-backend
systemctl restart neighbor-backend

# 6. 验证
echo "[6/6] 验证部署..."
sleep 3
curl -s http://127.0.0.1:8000/health && echo ""
systemctl status neighbor-backend --no-pager -l
nginx -t

echo ""
echo "=========================================="
echo "  部署完成！"
echo "=========================================="
echo "  域名: https://$DOMAIN"
echo "  API 文档: http://$DOMAIN/docs"
echo "  后端日志: journalctl -u neighbor-backend -f"
echo "  Nginx 日志: tail -f $LOG_DIR/access.log"
echo ""

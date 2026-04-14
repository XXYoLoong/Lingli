# ============================================================
# 邻里 - 云端部署 (分步手动版)
# 第1步: 构建并打包
# 第2步: 手动 scp + ssh 部署
# ============================================================

$ErrorActionPreference = "Stop"
$Server = "root@8.153.38.232"
$Domain = "harmonycare.cn"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  邻里 - 云端部署" -ForegroundColor Cyan
Write-Host "  目标: $Server -> $Domain" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ========== 第1步: 构建前端 ==========
Write-Host "[1/3] 构建 Web 前端..." -ForegroundColor Yellow
Set-Location "$PSScriptRoot\Frontend"
if (-not (Test-Path "node_modules")) { npm install }
npm run build
Write-Host "  [OK] 前端构建完成" -ForegroundColor Green

# ========== 第2步: 打包 ==========
Write-Host "`n[2/3] 打包部署文件..." -ForegroundColor Yellow

$PkgDir = "$PSScriptRoot\deploy-pkg"
if (Test-Path $PkgDir) { Remove-Item $PkgDir -Recurse -Force }
New-Item -ItemType Directory -Path "$PkgDir\backend\app" -Force | Out-Null
New-Item -ItemType Directory -Path "$PkgDir\backend\alembic\versions" -Force | Out-Null
New-Item -ItemType Directory -Path "$PkgDir\web" -Force | Out-Null

# 后端
Copy-Item "$PSScriptRoot\Backend\app\*" "$PkgDir\backend\app\" -Recurse
Copy-Item "$PSScriptRoot\Backend\alembic\*" "$PkgDir\backend\alembic\" -Recurse -ErrorAction SilentlyContinue
Copy-Item "$PSScriptRoot\Backend\requirements.txt" "$PkgDir\backend\"
Copy-Item "$PSScriptRoot\Backend\alembic.ini" "$PkgDir\backend\" -ErrorAction SilentlyContinue

# 前端构建产物
Copy-Item "$PSScriptRoot\Frontend\dist\*" "$PkgDir\web\" -Recurse

# 部署脚本
$DeployScript = @'
#!/bin/bash
set -e
DOMAIN="__DOMAIN__"
APP_DIR="/opt/neighbor"
LOG_DIR="/var/log/neighbor"

echo ">>> 安装系统包..."
apt-get update -qq
apt-get install -y -qq python3 python3-pip python3-venv nginx

echo ">>> 创建目录..."
mkdir -p "$APP_DIR/backend" "$APP_DIR/web" "$LOG_DIR" "$APP_DIR/uploads"

echo ">>> 部署后端..."
# 创建虚拟环境
python3 -m venv "$APP_DIR/backend/venv" 2>/dev/null || true
"$APP_DIR/backend/venv/bin/pip" install -q fastapi uvicorn sqlalchemy pydantic pydantic-settings python-jose bcrypt python-multipart httpx python-dotenv email-validator 2>/dev/null
"$APP_DIR/backend/venv/bin/pip" install -q -r "$APP_DIR/backend/requirements.txt" 2>/dev/null

# 生成密钥
SECRET_KEY="neighbor-prod-$(openssl rand -hex 32)"
DASHSCOPE_API_KEY="${DASHSCOPE_API_KEY:-}"

cat > "$APP_DIR/backend/.env" << ENVEOF
DATABASE_URL=sqlite+pysqlite:///$APP_DIR/backend/neighbor.db
SECRET_KEY=$SECRET_KEY
DASHSCOPE_API_KEY=$DASHSCOPE_API_KEY
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

echo ">>> 初始化数据库..."
cd "$APP_DIR/backend"
"$APP_DIR/backend/venv/bin/python" -c "
from app.database import engine, Base
from app.models import *
Base.metadata.create_all(bind=engine)
from app.models.user import UserAccount, RoleEnum, WorkerProfile
from app.models.station import ServiceStation
from app.services.auth_service import hash_password
from app.database import SessionLocal
db = SessionLocal()
if not db.query(ServiceStation).first():
    s = ServiceStation(name='社区服务站', code='MAIN001', address='服务中心', contact_phone='13800000000', status='active')
    db.add(s); db.commit(); db.refresh(s)
    users = [
        ('admin','13800000000','admin123456',RoleEnum.ADMIN,'系统管理员',None),
        ('manager','13800000001','manager123',RoleEnum.STATION_MANAGER,'张站长',s.id),
        ('worker','13800000002','worker123',RoleEnum.WORKER,'李师傅',s.id),
        ('resident','13800000003','resident123',RoleEnum.RESIDENT,'王居民',s.id),
    ]
    for u, p, pwd, r, n, sid in users:
        if not db.query(UserAccount).filter(UserAccount.phone == p).first():
            usr = UserAccount(username=u, phone=p, password_hash=hash_password(pwd), role=r, real_name=n, station_id=sid, is_active=True, is_verified=True)
            db.add(usr)
            if r == RoleEnum.WORKER:
                db.flush()
                db.add(WorkerProfile(user_id=usr.id, max_load=10, status='available'))
    db.commit()
    print('  测试账号: admin/13800000000 / admin123456')
db.close()
print('  数据库初始化完成')
" 2>&1

echo ">>> 配置 Nginx..."
cat > /etc/nginx/sites-available/neighbor << NGINXEOF
server {
    listen 80;
    server_name $DOMAIN;
    client_max_body_size 20M;

    location / {
        root $APP_DIR/web;
        try_files \$uri \$uri/ /index.html;
        expires 1d;
        add_header Cache-Control "public, no-transform";
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 30s;
        proxy_read_timeout 60s;
    }

    access_log $LOG_DIR/access.log;
    error_log $LOG_DIR/error.log;
}
NGINXEOF

ln -sf /etc/nginx/sites-available/neighbor /etc/nginx/sites-enabled/neighbor
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo ">>> 配置 systemd..."
cat > /etc/systemd/system/neighbor-backend.service << SVCEOF
[Unit]
Description=Neighbor Backend Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$APP_DIR/backend
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

sleep 2
echo ""
echo "=========================================="
echo "  部署完成！"
echo "=========================================="
echo "  网站: http://$Domain"
echo "  API:  http://$Domain/api/v1"
echo "  文档: http://$Domain/docs"
echo ""
echo "  测试账号:"
echo "    管理员: 13800000000 / admin123456"
echo "    站长:   13800000001 / manager123"
echo "    服务:   13800000002 / worker123"
echo "    居民:   13800000003 / resident123"
echo ""
'@

$DeployScript = $DeployScript -replace "__DOMAIN__", $Domain
Set-Content "$PkgDir\deploy.sh" -Value $DeployScript

# 打包
Compress-Archive -Path "$PkgDir\*" -DestinationPath "$PSScriptRoot\neighbor-deploy.zip" -Force
$ZipSize = [math]::Round((Get-Item "$PSScriptRoot\neighbor-deploy.zip").Length / 1MB, 2)
Write-Host "  [OK] 打包完成 (neighbor-deploy.zip, $ZipSize MB)" -ForegroundColor Green

# ========== 第3步: 提示手动部署 ==========
Write-Host "`n[3/3] 请手动执行以下命令完成部署:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  # 1. 上传到服务器" -ForegroundColor DarkGray
Write-Host "  scp neighbor-deploy.zip $($Server):/tmp/" -ForegroundColor White
Write-Host ""
Write-Host "  # 2. SSH 登录并解压部署" -ForegroundColor DarkGray
Write-Host "  ssh $Server" -ForegroundColor White
Write-Host "  cd /tmp`; unzip -o neighbor-deploy.zip -d /tmp/neighbor-deploy" -ForegroundColor White
Write-Host "  bash /tmp/neighbor-deploy/deploy.sh" -ForegroundColor White
Write-Host ""
Write-Host "  # 3. SSL 证书 (可选, 使用 Let's Encrypt)" -ForegroundColor DarkGray
Write-Host "  ssh $Server `'apt install -y certbot python3-certbot-nginx `; certbot --nginx -d $Domain`'" -ForegroundColor White
Write-Host ""

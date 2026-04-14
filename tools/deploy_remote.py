import os
import stat
import textwrap
import zipfile
from pathlib import Path

import paramiko


ROOT = Path(__file__).resolve().parent.parent
DIST_ZIP = ROOT / "neighbor-deploy-auto.zip"
HOST = "8.153.38.232"
USER = "root"
PASSWORD = "5211005_jc"
KEY_PATH = Path.home() / ".ssh" / "id_rsa"
KEY_PASSPHRASE = "5211005jc"
DOMAIN = "harmonycare.cn"


def should_skip(path: Path) -> bool:
    parts = set(path.parts)
    if "__pycache__" in parts or ".git" in parts or "venv" in parts:
        return True
    suffix = path.suffix.lower()
    if suffix in {".pyc", ".pyo"}:
        return True
    return False


def zip_dir(zipf: zipfile.ZipFile, src_dir: Path, arc_prefix: str) -> None:
    for p in src_dir.rglob("*"):
        if p.is_file() and not should_skip(p):
            rel = p.relative_to(src_dir)
            zipf.write(p, f"{arc_prefix}/{rel.as_posix()}")


def build_package() -> None:
    frontend_dist = ROOT / "Frontend" / "dist"
    backend_app = ROOT / "Backend" / "app"
    backend_req = ROOT / "Backend" / "requirements.txt"
    alembic_ini = ROOT / "Backend" / "alembic.ini"
    alembic_dir = ROOT / "Backend" / "alembic"

    if not frontend_dist.exists():
        raise RuntimeError("Frontend/dist 不存在，请先执行前端构建。")

    with zipfile.ZipFile(DIST_ZIP, "w", zipfile.ZIP_DEFLATED) as zipf:
        zip_dir(zipf, backend_app, "backend/app")
        zipf.write(backend_req, "backend/requirements.txt")

        if alembic_ini.exists():
            zipf.write(alembic_ini, "backend/alembic.ini")
        if alembic_dir.exists():
            zip_dir(zipf, alembic_dir, "backend/alembic")

        zip_dir(zipf, frontend_dist, "web")

    print(f"[OK] 部署包已生成: {DIST_ZIP}")


def remote_script() -> str:
    return textwrap.dedent(
        f"""
        #!/usr/bin/env bash
        set -e

        DOMAIN="{DOMAIN}"
        APP_DIR="/opt/neighbor"
        PKG_DIR="/tmp/neighbor-deploy"
        LOG_DIR="/var/log/neighbor"

        apt-get update -qq
        apt-get install -y -qq python3 python3-pip python3-venv nginx unzip rsync

        rm -rf "$PKG_DIR"
        mkdir -p "$PKG_DIR"
        unzip -o /tmp/neighbor-deploy-auto.zip -d "$PKG_DIR" >/dev/null

        mkdir -p "$APP_DIR/backend" "$APP_DIR/web" "$APP_DIR/uploads" "$LOG_DIR"

        rsync -a --delete "$PKG_DIR/backend/app/" "$APP_DIR/backend/app/"
        rsync -a --delete "$PKG_DIR/web/" "$APP_DIR/web/"
        cp "$PKG_DIR/backend/requirements.txt" "$APP_DIR/backend/requirements.txt"
        if [ -f "$PKG_DIR/backend/alembic.ini" ]; then cp "$PKG_DIR/backend/alembic.ini" "$APP_DIR/backend/alembic.ini"; fi
        if [ -d "$PKG_DIR/backend/alembic" ]; then
          mkdir -p "$APP_DIR/backend/alembic"
          rsync -a "$PKG_DIR/backend/alembic/" "$APP_DIR/backend/alembic/"
        fi

        python3 -m venv "$APP_DIR/backend/venv"
        "$APP_DIR/backend/venv/bin/pip" install -q --upgrade pip
        "$APP_DIR/backend/venv/bin/pip" install -q -r "$APP_DIR/backend/requirements.txt" email-validator bcrypt

        if [ ! -f "$APP_DIR/backend/.env" ]; then
          SECRET_KEY="neighbor-prod-$(openssl rand -hex 32)"
          cat > "$APP_DIR/backend/.env" << ENVEOF
DATABASE_URL=sqlite+pysqlite:///$APP_DIR/backend/neighbor.db
SECRET_KEY=$SECRET_KEY
DASHSCOPE_API_KEY=
QWEN_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
QWEN_MODEL_DEFAULT=qwen-plus
QWEN_MODEL_REVIEW=qwen-plus
QWEN_MODEL_SUMMARY=qwen-flash
QWEN_TIMEOUT=30
QWEN_MAX_RETRIES=3
UPLOAD_DIR=$APP_DIR/uploads
MAX_UPLOAD_SIZE=10485760
CORS_ORIGINS=["https://$DOMAIN","http://$DOMAIN","http://localhost:5173","http://127.0.0.1:5173"]
LOG_LEVEL=INFO
ENVEOF
        fi

        cd "$APP_DIR/backend"
        "$APP_DIR/backend/venv/bin/python" - << 'PYEOF'
from app.database import Base, engine, SessionLocal
from app.models import *
from app.models.user import UserAccount, WorkerProfile, RoleEnum
from app.models.station import ServiceStation
from app.services.auth_service import hash_password

Base.metadata.create_all(bind=engine)
db = SessionLocal()
try:
    station = db.query(ServiceStation).first()
    if station is None:
        station = ServiceStation(
            name="社区服务站",
            code="MAIN001",
            address="服务中心",
            contact_phone="13800000000",
            status="active",
        )
        db.add(station)
        db.commit()
        db.refresh(station)

    users = [
        ("admin", "13800000000", "admin123456", RoleEnum.ADMIN, "系统管理员", None),
        ("manager", "13800000001", "manager123", RoleEnum.STATION_MANAGER, "张站长", station.id),
        ("worker", "13800000002", "worker123", RoleEnum.WORKER, "李师傅", station.id),
        ("resident", "13800000003", "resident123", RoleEnum.RESIDENT, "王居民", station.id),
    ]
    for username, phone, password, role, name, station_id in users:
        exists = db.query(UserAccount).filter(UserAccount.phone == phone).first()
        if exists:
            continue
        user = UserAccount(
            username=username,
            phone=phone,
            password_hash=hash_password(password),
            role=role,
            real_name=name,
            station_id=station_id,
            is_active=True,
            is_verified=True,
        )
        db.add(user)
        db.flush()
        if role == RoleEnum.WORKER:
            db.add(WorkerProfile(user_id=user.id, max_load=10, status="available"))
    db.commit()
finally:
    db.close()
print("DB_INIT_OK")
PYEOF

        cat > /etc/systemd/system/neighbor-backend.service << SVCEOF
[Unit]
Description=Neighbor Backend Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$APP_DIR/backend
EnvironmentFile=$APP_DIR/backend/.env
ExecStart=$APP_DIR/backend/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 2
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVCEOF

        cat > /etc/nginx/sites-available/neighbor << NGINXEOF
server {{
    listen 80;
    server_name $DOMAIN;
    client_max_body_size 20M;

    location / {{
        root $APP_DIR/web;
        try_files \\$uri \\$uri/ /index.html;
    }}

    location /api/ {{
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \\$host;
        proxy_set_header X-Real-IP \\$remote_addr;
        proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\$scheme;
    }}
}}
NGINXEOF

        ln -sf /etc/nginx/sites-available/neighbor /etc/nginx/sites-enabled/neighbor
        rm -f /etc/nginx/sites-enabled/default
        nginx -t
        systemctl daemon-reload
        systemctl enable neighbor-backend >/dev/null 2>&1 || true
        systemctl restart neighbor-backend
        systemctl reload nginx

        sleep 2
        curl -fsS http://127.0.0.1:8000/health
        curl -I -s http://127.0.0.1 | head -n 1
        echo "DEPLOY_OK"
        """
    ).strip()


def connect_ssh() -> paramiko.SSHClient:
    pkey = paramiko.RSAKey.from_private_key_file(str(KEY_PATH), password=KEY_PASSPHRASE)
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=HOST,
        username=USER,
        password=PASSWORD,
        pkey=pkey,
        timeout=30,
        look_for_keys=False,
        allow_agent=False,
    )
    return client


def run_remote(client: paramiko.SSHClient, cmd: str) -> str:
    stdin, stdout, stderr = client.exec_command(cmd, get_pty=True, timeout=1200)
    out = stdout.read().decode("utf-8", errors="ignore")
    err = stderr.read().decode("utf-8", errors="ignore")
    code = stdout.channel.recv_exit_status()
    if code != 0:
        raise RuntimeError(f"远程命令失败({code})\n{out}\n{err}")
    return out + err


def main() -> None:
    build_package()
    client = connect_ssh()
    try:
        sftp = client.open_sftp()
        try:
            sftp.put(str(DIST_ZIP), "/tmp/neighbor-deploy-auto.zip")
            script_text = remote_script()
            remote_path = "/tmp/neighbor-deploy-run.sh"
            with sftp.file(remote_path, "w") as f:
                f.write(script_text)
            sftp.chmod(remote_path, stat.S_IRWXU)
        finally:
            sftp.close()

        output = run_remote(client, "bash /tmp/neighbor-deploy-run.sh")
        print(output)
        print("[OK] 已完成云端部署。")
        print(f"网站: http://{DOMAIN}")
        print(f"API: http://{DOMAIN}/api/v1")
    finally:
        client.close()


if __name__ == "__main__":
    main()

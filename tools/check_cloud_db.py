# Copyright 2026 Jiacheng Ni
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
from pathlib import Path

import paramiko


HOST = os.getenv("NEIGHBOR_DEPLOY_HOST", "")
USER = os.getenv("NEIGHBOR_DEPLOY_USER", "root")
PASSWORD = os.getenv("NEIGHBOR_DEPLOY_PASSWORD") or None
KEY_PASSPHRASE = os.getenv("NEIGHBOR_SSH_KEY_PASSPHRASE") or None
KEY_PATH = Path(os.getenv("NEIGHBOR_SSH_KEY_PATH", str(Path.home() / ".ssh" / "id_rsa")))


def run(client: paramiko.SSHClient, cmd: str) -> str:
    stdin, stdout, stderr = client.exec_command(cmd, get_pty=True, timeout=30)
    out = stdout.read().decode("utf-8", errors="ignore").strip()
    err = stderr.read().decode("utf-8", errors="ignore").strip()
    return out if out else err


def main() -> None:
    if not HOST:
        raise RuntimeError("请通过 NEIGHBOR_DEPLOY_HOST 环境变量设置目标服务器地址。")

    key = paramiko.RSAKey.from_private_key_file(str(KEY_PATH), password=KEY_PASSPHRASE)
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=HOST,
        username=USER,
        password=PASSWORD,
        pkey=key,
        look_for_keys=False,
        allow_agent=False,
        timeout=30,
    )
    try:
        commands = [
            "cd /opt/neighbor/backend && /opt/neighbor/backend/venv/bin/python - << 'PY'\nfrom app.config import settings\nfrom app.database import engine\nfrom sqlalchemy import inspect\nprint('DATABASE_URL=', settings.DATABASE_URL)\nprint('TABLES=', inspect(engine).get_table_names())\nPY",
            "cd /opt/neighbor/backend && /opt/neighbor/backend/venv/bin/python - << 'PY'\nfrom app.database import SessionLocal\nfrom app.models.user import UserAccount\nfrom app.models.order import ServiceOrder\ns=SessionLocal()\nprint('USERS=', s.query(UserAccount).count())\nprint('ORDERS=', s.query(ServiceOrder).count())\nfor o in s.query(ServiceOrder).order_by(ServiceOrder.created_at.desc()).limit(3).all():\n    print(o.order_no, o.status.value, o.created_at)\ns.close()\nPY",
        ]
        for cmd in commands:
            print(f"$ {cmd}")
            print(run(client, cmd))
            print("---")
    finally:
        client.close()


if __name__ == "__main__":
    main()

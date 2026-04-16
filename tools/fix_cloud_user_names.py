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
TARGET_USERNAME = os.getenv("NEIGHBOR_TARGET_USERNAME", "")
TARGET_REAL_NAME = os.getenv("NEIGHBOR_TARGET_REAL_NAME", "")
TARGET_NEW_USERNAME = os.getenv("NEIGHBOR_TARGET_NEW_USERNAME", "")


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
        cmd = """cd /opt/neighbor/backend && /opt/neighbor/backend/venv/bin/python - << 'PY'
from app.database import SessionLocal
from app.models.user import UserAccount

db = SessionLocal()
updated = 0
for user in db.query(UserAccount).all():
    name = user.real_name or ""
    if "?" in name or "�" in name:
        tail = user.phone[-4:] if user.phone else "0000"
        user.real_name = f"测试用户{tail}"
        updated += 1

target_username = {TARGET_USERNAME!r}
target_real_name = {TARGET_REAL_NAME!r}
target_new_username = {TARGET_NEW_USERNAME!r}
if target_username and target_real_name and target_new_username:
    for user in db.query(UserAccount).filter(UserAccount.username == target_username).all():
        user.real_name = target_real_name
        user.username = target_new_username
        updated += 1

db.commit()
print("UPDATED", updated)
db.close()
PY"""
        stdin, stdout, stderr = client.exec_command(cmd, get_pty=True, timeout=120)
        out = stdout.read().decode("utf-8", errors="ignore")
        err = stderr.read().decode("utf-8", errors="ignore")
        print(out)
        if err.strip():
            print(err)
    finally:
        client.close()


if __name__ == "__main__":
    main()

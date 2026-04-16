from pathlib import Path

import paramiko


HOST = "8.153.38.232"
USER = "root"
PASSWORD = "5211005_jc"
KEY_PASSPHRASE = "5211005jc"
KEY_PATH = Path.home() / ".ssh" / "id_rsa"


def main() -> None:
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

for user in db.query(UserAccount).filter(UserAccount.username == "u15655551005").all():
    user.real_name = "小小游龙"
    user.username = "xiaoxiaoyoulong"
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

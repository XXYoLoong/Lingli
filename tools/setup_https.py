from pathlib import Path

import paramiko


HOST = "8.153.38.232"
USER = "root"
PASSWORD = "5211005_jc"
KEY_PASSPHRASE = "5211005jc"
KEY_PATH = Path.home() / ".ssh" / "id_rsa"
DOMAIN = "harmonycare.cn"
EMAIL = "admin@harmonycare.cn"


def run(client: paramiko.SSHClient, cmd: str, timeout: int = 900) -> None:
    stdin, stdout, stderr = client.exec_command(cmd, get_pty=True, timeout=timeout)
    out = stdout.read().decode("utf-8", errors="ignore")
    err = stderr.read().decode("utf-8", errors="ignore")
    code = stdout.channel.recv_exit_status()
    print(out)
    if err.strip():
        print(err)
    if code != 0:
        raise RuntimeError(f"命令执行失败({code}): {cmd}")


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
        run(client, "apt-get update -qq && apt-get install -y -qq certbot python3-certbot-nginx")
        run(
            client,
            f"certbot --nginx -d {DOMAIN} --non-interactive --agree-tos -m {EMAIL} --redirect",
            timeout=1200,
        )
        run(client, "nginx -t && systemctl reload nginx")
        run(client, "curl -I -s http://harmonycare.cn | head -n 5")
        run(client, "curl -I -s https://harmonycare.cn | head -n 8")
        print("HTTPS_SETUP_OK")
    finally:
        client.close()


if __name__ == "__main__":
    main()

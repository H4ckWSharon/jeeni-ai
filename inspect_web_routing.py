import paramiko, sys

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('213.133.97.141', username='root', password='AfjbCUvqgdpST8', timeout=30)

cmds = [
    'docker inspect coolify-proxy | grep -iE "Host\("',
    'docker inspect ifc9cz1mdsnuu7f0a0uudp8r-144622969776 | grep -iE "Host\("',
    'cat /data/coolify/proxy/traefik.yaml 2>/dev/null',
    'cat /data/coolify/proxy/dynamic/*.yaml 2>/dev/null',
]

for cmd in cmds:
    print(f"=== {cmd} ===")
    stdin, stdout, stderr = ssh.exec_command(cmd)
    print(stdout.read().decode('utf-8', errors='replace'))

ssh.close()

import paramiko
import sys
import os
import time

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

host = '213.133.97.141'
user = 'root'
pwd  = 'AfjbCUvqgdpST8'

print(f"=== JEENI AI ADMIN OBSERVABILITY DEPLOYMENT TO {host} ===")

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, username=user, password=pwd, timeout=45)
print("1. SSH Connected successfully!")

def run_remote(cmd, label=""):
    print(f"\n[EXEC] {label or cmd}")
    stdin, stdout, stderr = ssh.exec_command(cmd)
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    if out:
        for line in out.split('\n')[:15]:
            print(f"   | {line}")
    if err:
        for line in err.split('\n')[:5]:
            print(f"   ! {line}")
    return out, err

sftp = ssh.open_sftp()

# Ensure directories exist
run_remote('mkdir -p /root/jeeni-server/src /root/jeeni-server/data /root/jeeni-server/public /var/www/jeeni/public', 'Ensuring remote directories')

files_to_upload = [
    ('server/src/studentStore.js', '/root/jeeni-server/src/studentStore.js'),
    ('server/src/usageStore.js', '/root/jeeni-server/src/usageStore.js'),
    ('server/src/adminAuth.js', '/root/jeeni-server/src/adminAuth.js'),
    ('server/src/aiGateway.js', '/root/jeeni-server/src/aiGateway.js'),
    ('server/server.js', '/root/jeeni-server/server.js'),
    ('server/public/admin.html', '/root/jeeni-server/public/admin.html'),
    ('server/public/admin.html', '/var/www/jeeni/public/admin.html'),
]

for local_path, remote_path in files_to_upload:
    print(f"\nUploading {local_path} -> {remote_path}...")
    with open(local_path, 'r', encoding='utf-8') as f:
        content = f.read()
    with sftp.file(remote_path, 'w') as f:
        f.write(content)
    print(f"   ✔ {remote_path} uploaded successfully ({len(content)} bytes)")

sftp.close()

# Restart PM2 process
print("\nRestarting PM2 process jeeni-server...")
run_remote('pm2 restart jeeni-server', 'Restarting jeeni-server')

time.sleep(3)

# Check PM2 status
run_remote('pm2 status', 'PM2 Process Status')

# Check recent PM2 logs
run_remote('pm2 logs jeeni-server --lines 20 --nostream', 'Recent PM2 Server Logs')

# Test local endpoint on VPS
run_remote("curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/admin/dashboard", "Test unauthenticated admin endpoint (Expect 401)")

ssh.close()
print("\n=== DEPLOYMENT COMPLETED SUCCESSFULLY ===")

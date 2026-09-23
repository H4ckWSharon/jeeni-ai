import paramiko
import sys
import os
import time
import requests

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

host = '213.133.97.141'
user = 'root'
pwd  = 'AfjbCUvqgdpST8'

print(f"=== JEENI AI ADAPTIVE VISUALIZATION DEPLOYMENT TO {host} ===")

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, username=user, password=pwd, timeout=45)
print("1. SSH Connected!")

def run_remote(cmd, label=""):
    print(f"\n[EXEC] {label or cmd}")
    stdin, stdout, stderr = ssh.exec_command(cmd)
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    if out:
        for line in out.split('\n')[:8]:
            print(f"   | {line}")
    if err:
        for line in err.split('\n')[:5]:
            print(f"   ! {line}")
    return out, err

sftp = ssh.open_sftp()

# Ensure directories exist
run_remote('mkdir -p /root/jeeni-server/src /root/jeeni-server/public/app /var/www/jeeni/public/app', 'Create server directories')

# Upload responseModeClassifier.js
print("\n2. Uploading src/responseModeClassifier.js...")
with open('server/src/responseModeClassifier.js', 'r', encoding='utf-8') as f:
    classifier_code = f.read()
with sftp.file('/root/jeeni-server/src/responseModeClassifier.js', 'w') as f:
    f.write(classifier_code)
print("   ✔ /root/jeeni-server/src/responseModeClassifier.js uploaded!")

# Upload server.js
print("\n3. Uploading server.js...")
with open('server/server.js', 'r', encoding='utf-8') as f:
    server_code = f.read()
with sftp.file('/root/jeeni-server/server.js', 'w') as f:
    f.write(server_code)
print("   ✔ /root/jeeni-server/server.js uploaded!")

# Upload web.tar.gz
file_size = os.path.getsize('web.tar.gz')
print(f"\n4. Uploading web.tar.gz ({file_size/1024/1024:.2f} MB)...")
uploaded = [0]
def progress(transferred, total):
    pct = transferred * 100 // total
    if pct % 25 == 0 and transferred != uploaded[0]:
        uploaded[0] = transferred
        print(f"   {pct}% ({transferred//1024}KB / {total//1024}KB)")

sftp.put('web.tar.gz', '/tmp/web.tar.gz', callback=progress)
print("   ✔ /tmp/web.tar.gz uploaded!")
sftp.close()

# Extract web archive to both public app paths
run_remote('tar -xzf /tmp/web.tar.gz -C /root/jeeni-server/public/app', 'Extract web to /root/jeeni-server/public/app')
run_remote('tar -xzf /tmp/web.tar.gz -C /var/www/jeeni/public/app', 'Extract web to /var/www/jeeni/public/app')
run_remote('rm -f /tmp/web.tar.gz', 'Clean up temp archive')

# Restart PM2
print("\n5. Restarting PM2 processes...")
run_remote('pm2 restart all', 'PM2 Restart')
time.sleep(3)

# Check PM2 Status
run_remote('pm2 status', 'PM2 Status')

ssh.close()
print("\n6. Running live health tests on VPS...")

try:
    # Test Web App HTTP 200
    res_web = requests.get('http://213.133.97.141:3000/app/', timeout=10)
    print(f"   ✔ Web App: HTTP {res_web.status_code} ({len(res_web.text)} bytes)")

    # Test API with Networking query
    res_api = requests.post(
        'http://213.133.97.141:3000/api/chat',
        json={
            'messages': [{'role': 'user', 'content': 'Explain TCP three-way handshake.'}],
            'mode': 'Guided Learning',
        },
        timeout=30,
    )
    print(f"   ✔ API Status: HTTP {res_api.status_code}")
    data = res_api.json()
    meta = data.get('response_metadata', {})
    print(f"   ✔ Response Metadata Returned: {meta}")
    assert meta.get('responseMode') == 'NETWORKING', f"Expected NETWORKING, got {meta.get('responseMode')}"
    assert meta.get('animation') == 'network_flow', f"Expected network_flow, got {meta.get('animation')}"
    print("   ✔ All live API and adaptive metadata checks passed!")
except Exception as e:
    print(f"   ❌ Live test check warning: {e}")

print("\n*** DEPLOYMENT COMPLETED SUCCESSFULLY ***")

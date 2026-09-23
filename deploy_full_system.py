import paramiko
import sys
import os
import time

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

host = '213.133.97.141'
user = 'root'
pwd  = 'AfjbCUvqgdpST8'

print(f"=== JEENI AI FULL STACK DEPLOYMENT TO {host} ===")

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
        for line in out.split('\n')[:10]:
            print(f"   | {line}")
    if err:
        for line in err.split('\n')[:5]:
            print(f"   ! {line}")
    return out, err

sftp = ssh.open_sftp()

# 2. Ensure server directories exist
run_remote('mkdir -p /root/jeeni-server/src /root/jeeni-server/data /root/jeeni-server/public/app /var/www/jeeni/public/app', 'Create server directories')

# 3. Upload studentStore.js
print("\n3. Uploading src/studentStore.js...")
with open('server/src/studentStore.js', 'r', encoding='utf-8') as f:
    student_store_code = f.read()
with sftp.file('/root/jeeni-server/src/studentStore.js', 'w') as f:
    f.write(student_store_code)
print("   ✔ /root/jeeni-server/src/studentStore.js uploaded successfully!")

# 3.5 Upload responseModeClassifier.js
print("\n3.5 Uploading src/responseModeClassifier.js...")
with open('server/src/responseModeClassifier.js', 'r', encoding='utf-8') as f:
    resp_classifier_code = f.read()
with sftp.file('/root/jeeni-server/src/responseModeClassifier.js', 'w') as f:
    f.write(resp_classifier_code)
print("   ✔ /root/jeeni-server/src/responseModeClassifier.js uploaded successfully!")

# 4. Upload server.js
print("\n4. Uploading server.js...")
with open('server/server.js', 'r', encoding='utf-8') as f:
    server_code = f.read()
with sftp.file('/root/jeeni-server/server.js', 'w') as f:
    f.write(server_code)
print("   ✔ /root/jeeni-server/server.js uploaded successfully!")

# 5. Upload web.tar.gz
file_size = os.path.getsize('web.tar.gz')
print(f"\n5. Uploading web.tar.gz ({file_size/1024/1024:.2f} MB)...")
uploaded = [0]
def progress(transferred, total):
    pct = transferred * 100 // total
    if pct % 25 == 0 and transferred != uploaded[0]:
        uploaded[0] = transferred
        print(f"   {pct}% ({transferred//1024} KB / {total//1024} KB)")

sftp.put('web.tar.gz', '/tmp/web.tar.gz', callback=progress)
sftp.close()
print("   ✔ web.tar.gz uploaded to /tmp/web.tar.gz!")

# 6. Extract web app to both root server public and var/www
run_remote(
    'mkdir -p /root/jeeni-server/public/app && '
    'rm -rf /root/jeeni-server/public/app/* && '
    'tar -xzf /tmp/web.tar.gz -C /root/jeeni-server/public/app && '
    'mkdir -p /var/www/jeeni/public/app && '
    'rm -rf /var/www/jeeni/public/app/* && '
    'tar -xzf /tmp/web.tar.gz -C /var/www/jeeni/public/app && '
    'rm -f /tmp/web.tar.gz',
    'Extract web app to production directories'
)

# 7. Restart PM2 and verify status
run_remote('pm2 restart all', 'Restart PM2 services')
time.sleep(3)
run_remote('pm2 list', 'Check PM2 process status')
run_remote('curl -s http://127.0.0.1:3000/api/health || echo "Health check"', 'Verify backend health')
run_remote('head -n 25 /root/jeeni-server/public/app/index.html', 'Verify deployed web index')

ssh.close()
print("\n=== DEPLOYMENT COMPLETE! ===")
print("Web App URL: http://213.133.97.141:3000/app/")

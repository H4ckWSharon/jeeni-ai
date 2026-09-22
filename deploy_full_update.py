import paramiko
import sys
import os
import tarfile
import time
import json

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

host = '213.133.97.141'
user = 'root'
pwd  = 'AfjbCUvqgdpST8'

print("=== STEP 1: Creating fresh web.tar.gz from flutter/build/web ===")
archive_name = 'web.tar.gz'
if os.path.exists(archive_name):
    os.remove(archive_name)

with tarfile.open(archive_name, 'w:gz') as tar:
    tar.add('flutter/build/web', arcname='.')

archive_size = os.path.getsize(archive_name)
print(f"Created {archive_name} ({archive_size / (1024*1024):.2f} MB)")

print("\n=== STEP 2: Connecting to VPS via SSH ===")
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, username=user, password=pwd, timeout=45)
print("Connected successfully!")

sftp = ssh.open_sftp()

print("\n=== STEP 3: Uploading updated server.js ===")
with open('server/server.js', 'r', encoding='utf-8') as f:
    server_js = f.read()

# Upload to both locations
for remote_srv in ['/root/jeeni-server/server.js', '/var/www/jeeni/server.js']:
    try:
        with sftp.file(remote_srv, 'w') as f:
            f.write(server_js)
        print(f"  ✔ Uploaded to {remote_srv} ({len(server_js)} bytes)")
    except Exception as e:
        print(f"  ! Failed uploading to {remote_srv}: {e}")

print("\n=== STEP 4: Uploading web.tar.gz ===")
uploaded = [0]
def progress(transferred, total):
    pct = transferred * 100 // total
    if pct % 20 == 0 and transferred != uploaded[0]:
        uploaded[0] = transferred
        print(f"   {pct}% ({transferred//1024}KB / {total//1024}KB)")

sftp.put(archive_name, '/tmp/web.tar.gz', callback=progress)
print("  ✔ Uploaded /tmp/web.tar.gz")
sftp.close()

print("\n=== STEP 5: Extracting web app to /root/jeeni-server and /var/www/jeeni ===")
commands = [
    "mkdir -p /root/jeeni-server/public/app /var/www/jeeni/public/app",
    "tar -xzf /tmp/web.tar.gz -C /root/jeeni-server/public/app",
    "tar -xzf /tmp/web.tar.gz -C /var/www/jeeni/public/app",
    "chmod -R 755 /root/jeeni-server/public/app /var/www/jeeni/public/app",
    "rm /tmp/web.tar.gz"
]
cmd_str = " && ".join(commands)
stdin, stdout, stderr = ssh.exec_command(cmd_str)
exit_status = stdout.channel.recv_exit_status()
if exit_status == 0:
    print("  ✔ Extracted to both directories successfully!")
else:
    print(f"  ! Extract error: {stderr.read().decode()}")

print("\n=== STEP 6: Restarting PM2 ===")
stdin, stdout, stderr = ssh.exec_command("pm2 restart all")
print(stdout.read().decode('utf-8', errors='ignore')[:400])

time.sleep(3)

print("\n=== STEP 7: Verifying Live Web App on VPS ===")
stdin, stdout, stderr = ssh.exec_command("curl -s -I http://localhost:3000/app/main.dart.js | grep -iE 'last-modified|content-length'")
print("main.dart.js headers on VPS:")
print(stdout.read().decode('utf-8', errors='ignore'))

stdin, stdout, stderr = ssh.exec_command("curl -s http://localhost:3000/app/version.json")
print("version.json on VPS:")
print(stdout.read().decode('utf-8', errors='ignore'))

print("\n=== STEP 8: Testing Zero-Chunks API for Class 5 Query ===")
test_payload = json.dumps({
    "messages": [{"role": "user", "content": "explain the class 5 chapter 8"}],
    "student_id": "test_student_cls5",
    "studentProfile": {
        "class": "Class 10",
        "board": "CBSE"
    }
})
test_cmd = f"curl -s -X POST http://localhost:3000/api/chat -H 'Content-Type: application/json' -d '{test_payload}'"
stdin, stdout, stderr = ssh.exec_command(test_cmd)
api_res = stdout.read().decode('utf-8', errors='ignore')
print("API Response for 'explain the class 5 chapter 8':")
print(api_res[:400])

ssh.close()
print("\n=== DEPLOYMENT & VERIFICATION COMPLETE ===")

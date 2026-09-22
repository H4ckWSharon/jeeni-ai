import paramiko, os, sys, time

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

FILES_TO_UPLOAD = [
    ('server/server.js', 'server.js'),
    ('server/src/zeroChunksHandler.js', 'src/zeroChunksHandler.js'),
    ('server/src/studentStore.js', 'src/studentStore.js'),
    ('server/src/usageStore.js', 'src/usageStore.js'),
]

TARGET_DIRS = [
    '/root/jeeni-server',
    '/var/www/jeeni',
]

print("Connecting to VPS 213.133.97.141...")
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('213.133.97.141', username='root', password='AfjbCUvqgdpST8', timeout=30)
print("Connected successfully.")

sftp = ssh.open_sftp()

for local_path, rel_target in FILES_TO_UPLOAD:
    with open(local_path, 'r', encoding='utf-8') as f:
        content = f.read()

    for base_dir in TARGET_DIRS:
        remote_path = f"{base_dir}/{rel_target}"
        try:
            # Ensure parent dir exists
            parent_dir = os.path.dirname(remote_path).replace('\\', '/')
            try:
                sftp.stat(parent_dir)
            except IOError:
                sftp.mkdir(parent_dir)

            with sftp.file(remote_path, 'w') as rf:
                rf.write(content)
            print(f"✓ Uploaded {local_path} -> {remote_path} ({len(content)} bytes)")
        except Exception as e:
            print(f"✗ Failed {remote_path}: {e}")

sftp.close()

print("\nRestarting PM2 on VPS...")
stdin, stdout, stderr = ssh.exec_command('pm2 restart all && pm2 status')
print("STDOUT:\n", stdout.read().decode('utf-8', errors='replace'))
err = stderr.read().decode('utf-8', errors='replace')
if err:
    print("STDERR:\n", err)

time.sleep(2)

print("\nVerifying Live Endpoint Health...")
test_cmd = """curl -s -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Explain Class 8 Chapter 2"}],"studentId":"vps_test_student"}'
"""
stdin, stdout, stderr = ssh.exec_command(test_cmd)
output = stdout.read().decode('utf-8', errors='replace')
print("Class 8 Chapter 2 response from VPS:")
print(output[:500])

ssh.close()
print("\nVPS DEPLOYMENT AND VERIFICATION FINISHED!")

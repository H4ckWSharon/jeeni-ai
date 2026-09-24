import paramiko, os, sys, time, json, requests

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

FILES_TO_UPLOAD = [
    ('server/server.js', 'server.js'),
    ('server/src/responseModeClassifier.js', 'src/responseModeClassifier.js'),
    ('server/test_orchestration_orchestrator.js', 'test_orchestration_orchestrator.js'),
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

time.sleep(3)

print("\nRunning test_orchestration_orchestrator.js on VPS /root/jeeni-server...")
stdin, stdout, stderr = ssh.exec_command('cd /root/jeeni-server && node test_orchestration_orchestrator.js')
remote_test_output = stdout.read().decode('utf-8', errors='replace')
print(remote_test_output)
test_err = stderr.read().decode('utf-8', errors='replace')
if test_err:
    print("TEST STDERR:\n", test_err)

ssh.close()
print("\nVPS deployment complete. Now running live verification against public endpoint...")

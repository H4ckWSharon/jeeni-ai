import paramiko, sys, os

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

local_apk = 'server/public/jeeni-app.apk'
remote_targets = [
    '/root/jeeni-server/public/jeeni-app.apk',
    '/var/www/jeeni/public/jeeni-app.apk',
]

print("Connecting to VPS 213.133.97.141...")
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('213.133.97.141', username='root', password='AfjbCUvqgdpST8', timeout=30)
print("Connected successfully.")

sftp = ssh.open_sftp()
size_mb = os.path.getsize(local_apk) / (1024 * 1024)
print(f"Uploading APK ({size_mb:.1f} MB)...")

for target in remote_targets:
    try:
        parent = os.path.dirname(target).replace('\\', '/')
        try:
            sftp.stat(parent)
        except IOError:
            sftp.mkdir(parent)

        print(f"Transferring to {target}...")
        sftp.put(local_apk, target)
        print(f"✓ Uploaded successfully to {target}")
    except Exception as e:
        print(f"✗ Failed {target}: {e}")

sftp.close()

# Verify via curl on VPS
stdin, stdout, stderr = ssh.exec_command('curl -s -I http://localhost:3000/jeeni-app.apk')
print("\nLocalhost:3000 Header Check:\n", stdout.read().decode('utf-8', errors='replace'))

ssh.close()
print("APK DEPLOYMENT COMPLETE!")

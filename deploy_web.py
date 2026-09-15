import paramiko
import sys
import time

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

host = '213.133.97.141'
user = 'root'
pwd  = 'AfjbCUvqgdpST8'
remote_path = '/var/www/jeeni/public/app'

print("1. Connecting to VPS via SSH...")
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, username=user, password=pwd, timeout=30)
print("Connected!")

sftp = ssh.open_sftp()

print("\n2. Uploading web.tar.gz to /tmp/web.tar.gz...")
sftp.put('web.tar.gz', '/tmp/web.tar.gz')
print("Uploaded web.tar.gz!")
sftp.close()

print("\n3. Extracting archive on VPS...")
extract_cmd = f"mkdir -p {remote_path} && tar -xzf /tmp/web.tar.gz -C {remote_path} && rm /tmp/web.tar.gz"
_, stdout, stderr = ssh.exec_command(extract_cmd)
exit_status = stdout.channel.recv_exit_status()
if exit_status == 0:
    print("Extracted successfully!")
else:
    print(f"Extraction failed: {stderr.read().decode()}")

print("\n4. Restarting PM2 process 'all'...")
_, stdout, stderr = ssh.exec_command('pm2 restart all')
print("PM2 restart output:")
print(stdout.read().decode('utf-8', errors='ignore')[:300])

ssh.close()
print("\n*** FLUTTER WEB APP DEPLOYED TO http://213.133.97.141:3000/app ***")

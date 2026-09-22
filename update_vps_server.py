import paramiko, os, sys

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('213.133.97.141', username='root', password='AfjbCUvqgdpST8', timeout=30)

with open('server/server.js', 'r', encoding='utf-8') as f:
    server_js = f.read()

sftp = ssh.open_sftp()
for p in ['/root/jeeni-server/server.js', '/var/www/jeeni/server.js']:
    try:
        with sftp.file(p, 'w') as f:
            f.write(server_js)
        print(f"Updated {p} ({len(server_js)} bytes)")
    except Exception as e:
        print(f"Failed {p}: {e}")
sftp.close()

stdin, stdout, stderr = ssh.exec_command('pm2 restart all && echo PM2_RESTARTED')
print("STDOUT:", stdout.read().decode('utf-8', errors='replace'))
print("STDERR:", stderr.read().decode('utf-8', errors='replace'))

ssh.close()
print("UPDATED SERVER.JS ON VPS!")

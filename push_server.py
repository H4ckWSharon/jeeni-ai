import paramiko, sys
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

host = '213.133.97.141'
user = 'root'
pwd = 'AfjbCUvqgdpST8'

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, username=user, password=pwd, timeout=30)

# Upload the fixed server.js
print('Uploading fixed server.js to /root/jeeni-server/server.js ...')
with open('server/server.js', 'r', encoding='utf-8') as f:
    server_js = f.read()

sftp = ssh.open_sftp()
with sftp.file('/root/jeeni-server/server.js', 'w') as f:
    f.write(server_js)
sftp.close()
print('server.js uploaded!')

# Restart PM2
stdin, stdout, stderr = ssh.exec_command('pm2 restart jeeni-server && echo RESTARTED')
out = stdout.read().decode('utf-8', errors='replace')
err = stderr.read().decode('utf-8', errors='replace')
print('OUT:', out[:300])
if err:
    print('ERR:', err[:200])

ssh.close()
print('DONE! Fixed server deployed to VPS.')

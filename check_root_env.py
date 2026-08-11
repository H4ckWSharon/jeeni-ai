import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('213.133.97.141', username='root', password='AfjbCUvqgdpST8')

_, o, _ = ssh.exec_command('grep -n "gemini-" /root/jeeni-server/server.js')
result = o.read().decode()
print('=== Gemini model lines in server.js (VPS) ===')
print(result)

_, o2, _ = ssh.exec_command('pm2 list')
print('=== PM2 Status ===')
print(o2.read().decode())

ssh.close()

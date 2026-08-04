import paramiko, os

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('213.133.97.141', username='root', password='AfjbCUvqgdpST8', timeout=30)

with open('server/server.js', 'r', encoding='utf-8') as f:
    server_js = f.read()

sftp = ssh.open_sftp()
with sftp.file('/var/www/jeeni/server.js', 'w') as f:
    f.write(server_js)
sftp.close()

stdin, stdout, stderr = ssh.exec_command('pm2 restart all && echo PM2_RESTARTED')
print("STDOUT:", stdout.read().decode())
print("STDERR:", stderr.read().decode())

ssh.close()
print("UPDATED SERVER.JS ON VPS!")

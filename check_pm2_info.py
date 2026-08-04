import paramiko, sys
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('213.133.97.141', username='root', password='AfjbCUvqgdpST8', timeout=30)

stdin, stdout, stderr = ssh.exec_command('pm2 info jeeni-server')
print(stdout.read().decode('utf-8', errors='ignore'))

ssh.close()

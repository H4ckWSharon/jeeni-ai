import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('213.133.97.141', username='root', password='AfjbCUvqgdpST8', timeout=30)

def exec_cmd(cmd):
    stdin, stdout, stderr = ssh.exec_command(cmd)
    out = stdout.read().decode('utf-8', errors='ignore')
    err = stderr.read().decode('utf-8', errors='ignore')
    print(f"=== CMD: {cmd} ===")
    print("STDOUT:", out[:500])
    if err:
        print("STDERR:", err[:500])

exec_cmd('grep -rn "imageBlacklist" /var/www/jeeni/public/')
exec_cmd('grep -rn "attached image" /var/www/jeeni/public/')
exec_cmd('grep -rn "deriveTopicSlug" /var/www/jeeni/public/')

ssh.close()

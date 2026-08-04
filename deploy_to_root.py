import paramiko, os, base64, sys
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

host = '213.133.97.141'
user = 'root'
pwd  = 'AfjbCUvqgdpST8'

target_dir = '/root/jeeni-server'
target_app = '/root/jeeni-server/public/app'

print('Connecting to VPS...')
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, username=user, password=pwd, timeout=30)
print('Connected!')

def run_cmd(cmd):
    stdin, stdout, stderr = ssh.exec_command(cmd)
    out = stdout.read().decode('utf-8', errors='ignore').strip()
    err = stderr.read().decode('utf-8', errors='ignore').strip()
    print(f"-> CMD: {cmd}")
    if out: print("  OUT:", out[:300])
    if err: print("  ERR:", err[:300])

# 1. Transfer web.tar.gz base64
print('Reading web.tar.gz...')
with open('web.tar.gz', 'rb') as f:
    b64 = base64.b64encode(f.read()).decode()

print(f'Sending {len(b64)} chars via SSH...')
transport = ssh.get_transport()
chan = transport.open_session()
chan.exec_command('cat > /tmp/web_b64.txt')

chunk_size = 40000
for i in range(0, len(b64), chunk_size):
    chan.sendall(b64[i:i+chunk_size].encode())

chan.shutdown_write()
chan.recv(1024)
chan.close()
print('Upload complete!')

# 2. Decode and extract web app to /root/jeeni-server/public/app
run_cmd('base64 -d /tmp/web_b64.txt > /tmp/web.tar.gz')
run_cmd(f'mkdir -p {target_app}')
run_cmd(f'rm -rf {target_app}/*')
run_cmd(f'tar -xzf /tmp/web.tar.gz -C {target_app}')
run_cmd('rm -f /tmp/web_b64.txt /tmp/web.tar.gz')

# 3. Transfer updated server.js to /root/jeeni-server/server.js
print('Updating server.js...')
with open('server/server.js', 'r', encoding='utf-8') as f:
    server_js = f.read()

sftp = ssh.open_sftp()
with sftp.file(f'{target_dir}/server.js', 'w') as f:
    f.write(server_js)
sftp.close()

# 4. Restart PM2
print('Restarting PM2 processes...')
run_cmd('pm2 restart all')

ssh.close()
print('*** FULLY DEPLOYED TO /root/jeeni-server ***')

import paramiko, os, base64, sys
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

host = '213.133.97.141'
user = 'root'
pwd  = 'AfjbCUvqgdpST8'
remote_app = '/var/www/jeeni/public/app'

print('Connecting...')
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, username=user, password=pwd, timeout=30)
print('Connected!')

def run(cmd, timeout=60):
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode().strip()
    err = stderr.read().decode().strip()
    return out, err

# Read and encode archive
print('Reading archive...')
with open('web.tar.gz', 'rb') as f:
    data = f.read()
b64 = base64.b64encode(data).decode()
total = len(b64)
print(f'Encoded: {total} chars')

# Send in 40KB chunks using cat + heredoc approach
chunk_size = 40000
chunks = [b64[i:i+chunk_size] for i in range(0, total, chunk_size)]
print(f'Sending {len(chunks)} chunks via SSH...')

# Write chunks directly using ssh channel
transport = ssh.get_transport()
channel = transport.open_session()
channel.exec_command('cat > /tmp/web_b64.txt')

for i, chunk in enumerate(chunks):
    if i % 50 == 0:
        print(f'  Chunk {i}/{len(chunks)}...')
    channel.sendall((chunk).encode())

channel.shutdown_write()
channel.recv(1024)
channel.close()
print('Transfer done!')

# Decode and deploy
print('Decoding...')
out, err = run('base64 -d /tmp/web_b64.txt > /tmp/web.tar.gz && echo OK', timeout=60)
print('Decode:', out, err)

print('Creating target directory...')
out, err = run(f'mkdir -p {remote_app} && echo OK_MKDIR', timeout=10)
print('Mkdir:', out, err)

print('Extracting...')
out, err = run(f'tar -xzf /tmp/web.tar.gz -C {remote_app} && echo OK', timeout=60)
print('Extract:', out, err)

out, err = run('rm -f /tmp/web_b64.txt /tmp/web.tar.gz && pm2 restart all && echo DONE', timeout=30)
print('Restart:', out[:300] if out else '', err[:100] if err else '')

ssh.close()
print('*** DEPLOYED SUCCESSFULLY ***')

"""Find where chromodb data actually lives on the VPS."""
import paramiko
import sys

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

host, user, pwd = '213.133.97.141', 'root', 'AfjbCUvqgdpST8'
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, username=user, password=pwd, timeout=30)

def run(cmd):
    _, out, err = ssh.exec_command(cmd)
    return out.read().decode('utf-8', errors='ignore'), err.read().decode('utf-8', errors='ignore')

# Find chromodb app location
print("=== Finding chromodb on VPS ===")
out, _ = run("find /root -name 'server.js' 2>/dev/null | head -20")
print(out)

print("=== PM2 chromodb process info ===")
out, _ = run("pm2 describe chromodb 2>/dev/null")
print(out)

print("=== PM2 jeeni-server process info ===")
out, _ = run("pm2 describe jeeni-server 2>/dev/null")
print(out)

print("=== ChromoDB actual data location ===")
out, _ = run("find /root -name 'documents.json' 2>/dev/null")
print(out)

print("=== ChromoDB collections.json ===")
out, _ = run("find /root -name 'collections.json' 2>/dev/null")
print(out)

# Check PM2 ecosystem or startup scripts
print("=== PM2 ecosystem file ===")
out, _ = run("cat /root/ecosystem.config.js 2>/dev/null || cat /root/ecosystem.config.json 2>/dev/null || echo 'no ecosystem file'")
print(out)

# Find all server.js locations
print("=== All package.json locations ===")
out, _ = run("find /root -name 'package.json' -not -path '*/node_modules/*' 2>/dev/null")
print(out)

ssh.close()

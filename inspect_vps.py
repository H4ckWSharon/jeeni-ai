"""Inspect VPS ChromoDB data and check what's actually stored."""
import paramiko
import json
import sys

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

host, user, pwd = '213.133.97.141', 'root', 'AfjbCUvqgdpST8'
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, username=user, password=pwd, timeout=30)
print("Connected to VPS!")

def run(cmd):
    _, out, err = ssh.exec_command(cmd)
    return out.read().decode('utf-8', errors='ignore'), err.read().decode('utf-8', errors='ignore')

# 1. Check chromodb data directory
print("\n=== 1. ChromoDB data directory ===")
out, _ = run("ls -la /root/jeeni-server/chromodb/data/ 2>/dev/null || echo 'dir not found'")
print(out)

# 2. Check collections.json
print("=== 2. Collections (VPS) ===")
out, _ = run("cat /root/jeeni-server/chromodb/data/collections.json 2>/dev/null || echo 'not found'")
print(out)

# 3. Check document counts per collection
print("=== 3. Document counts per collection ===")
out, _ = run("""
for dir in /root/jeeni-server/chromodb/data/*/; do
  if [ -f "$dir/documents.json" ]; then
    count=$(node -e "const d=require('$dir/documents.json'); console.log(d.length)" 2>/dev/null)
    echo "  $dir -> $count docs"
  fi
done
""")
print(out)

# 4. Check first doc metadata in each collection
print("=== 4. Sample doc metadata per collection ===")
out, _ = run("""
for dir in /root/jeeni-server/chromodb/data/*/; do
  if [ -f "$dir/documents.json" ]; then
    echo "--- $dir ---"
    node -e "const d=require('$dir/documents.json'); if(d.length>0){console.log('count:', d.length); console.log('first metadata:', JSON.stringify(d[0].metadata, null, 2)); console.log('vector len:', d[0].vector ? d[0].vector.length : 'NO VECTOR')}" 2>/dev/null
  fi
done
""")
print(out)

# 5. Check .env files
print("=== 5. Server .env ===")
out, _ = run("cat /root/jeeni-server/.env 2>/dev/null || echo '.env not found'")
print(out)

print("=== 6. ChromoDB .env ===")
out, _ = run("cat /root/jeeni-server/chromodb/.env 2>/dev/null || echo '.env not found'")
print(out)

# 6. Check PM2 process list
print("=== 7. PM2 Processes ===")
out, _ = run("pm2 list 2>/dev/null")
print(out)

# 7. Check server logs for errors
print("=== 8. Recent server logs (last 30 lines) ===")
out, _ = run("pm2 logs jeeni-server --lines 30 --nostream 2>/dev/null")
print(out[:3000])

print("=== 9. Recent chromodb logs (last 30 lines) ===")
out, _ = run("pm2 logs chromodb --lines 30 --nostream 2>/dev/null")
print(out[:3000])

ssh.close()
print("\nInspection complete!")

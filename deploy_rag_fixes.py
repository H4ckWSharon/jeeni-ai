"""Deploy all fixed server files to VPS."""
import paramiko
import sys

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

host, user, pwd = '213.133.97.141', 'root', 'AfjbCUvqgdpST8'
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, username=user, password=pwd, timeout=30)
print("Connected to VPS!")

sftp = ssh.open_sftp()

# Upload chromodb search.js (with normalization fix)
print("\nUploading chromodb/src/api/search.js...")
with open('server/chromodb/src/api/search.js', 'r', encoding='utf-8') as f:
    content = f.read()
with sftp.file('/root/chromodb/src/api/search.js', 'w') as f:
    f.write(content)
print("Done!")

sftp.close()

# Restart both services
print("\nRestarting all PM2 processes...")
_, out, err = ssh.exec_command('pm2 restart all')
out_text = out.read().decode('utf-8', errors='ignore')
print(out_text[:300])

import time
time.sleep(3)

# Quick live end-to-end test via jeeni-server chat API
print("\n=== Live E2E Test via /api/chat ===")

import json

def run(cmd):
    _, out, err = ssh.exec_command(cmd, timeout=30)
    return out.read().decode('utf-8', errors='ignore')

# Test 1: CBSE Class 10 English Lencho -> should find chunks
print("\nTest 1: CBSE Class 10 English Lencho character sketch")
out = run("""curl -s -X POST http://localhost:3000/api/chat \
  -H 'Content-Type: application/json' \
  -d '{"messages":[{"role":"user","content":"Write a character sketch of Lencho from CBSE Class 10 English First Flight"}]}' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('pipeline:', d.get('pipeline')); print('sources:', len(d.get('sources', []))); print('content snippet:', d.get('content','')[:120])"
""")
print(out)

# Test 2: Kerala Class 9 Biology -> should return ZERO_CHUNKS
print("\nTest 2: Kerala State Board Class 9 Biology (expect ZERO_CHUNKS)")
out = run("""curl -s -X POST http://localhost:3000/api/chat \
  -H 'Content-Type: application/json' \
  -d '{"messages":[{"role":"user","content":"Explain Chapter 1 Biology from Kerala State Board Class 9"}]}' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('pipeline:', d.get('pipeline')); print('type:', d.get('type')); print('tokens_saved:', d.get('tokens_saved'))"
""")
print(out)

ssh.close()
print("\nDeployment complete!")

import paramiko
import sys
import os
import time
import json

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

host = '213.133.97.141'
user = 'root'
pwd  = 'AfjbCUvqgdpST8'

print("=== STEP 1: Connecting to VPS via SSH ===")
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, username=user, password=pwd, timeout=45)
print("Connected successfully to VPS!")

sftp = ssh.open_sftp()

files_to_sync = [
    ('server/server.js', 'server.js'),
    ('server/src/zeroChunksHandler.js', 'src/zeroChunksHandler.js'),
    ('server/src/usageStore.js', 'src/usageStore.js'),
    ('server/src/aiGateway.js', 'src/aiGateway.js'),
    ('server/public/admin.html', 'public/admin.html'),
    ('server/test_grounding_integrity.js', 'test_grounding_integrity.js'),
]

print("\n=== STEP 2: Uploading Grounding & Provenance Files ===")
roots = ['/root/jeeni-server', '/var/www/jeeni']

for local_rel, remote_rel in files_to_sync:
    local_path = os.path.normpath(local_rel)
    with open(local_path, 'r', encoding='utf-8') as f:
        content = f.read()

    for root_dir in roots:
        remote_path = f"{root_dir}/{remote_rel}"
        remote_dir = os.path.dirname(remote_path)
        try:
            # Ensure dir exists
            ssh.exec_command(f"mkdir -p {remote_dir}")
            with sftp.file(remote_path, 'w') as rf:
                rf.write(content)
            print(f"  ✔ Synced: {remote_path} ({len(content)} bytes)")
        except Exception as e:
            print(f"  ! Error syncing {remote_path}: {e}")

sftp.close()

print("\n=== STEP 3: Restarting PM2 ===")
stdin, stdout, stderr = ssh.exec_command("pm2 restart all")
print(stdout.read().decode('utf-8', errors='ignore')[:300])

time.sleep(3)

print("\n=== STEP 4: Running Grounding Integrity Test Suite directly on VPS ===")
stdin, stdout, stderr = ssh.exec_command("cd /root/jeeni-server && node test_grounding_integrity.js")
out = stdout.read().decode('utf-8', errors='ignore')
err = stderr.read().decode('utf-8', errors='ignore')
print(out)
if err.strip():
    print("STDERR:", err)

print("\n=== STEP 5: Live API Verification Calls on VPS ===")

def test_api_call(title, payload):
    print(f"\n--- {title} ---")
    payload_json = json.dumps(payload)
    cmd = f"curl -s -X POST http://localhost:3000/api/chat -H 'Content-Type: application/json' -d '{payload_json}'"
    stdin, stdout, stderr = ssh.exec_command(cmd)
    res_str = stdout.read().decode('utf-8', errors='ignore')
    try:
        data = json.loads(res_str)
        print(f"Pipeline: {data.get('pipeline')}")
        print(f"Answer Source: {data.get('answer_source')}")
        print(f"Gemini Called: {data.get('gemini_called')}")
        print(f"Validation Status: {data.get('validation_status')}")
        print(f"Routing Action: {data.get('routing', {}).get('action')}")
        print(f"Content Preview: {data.get('content', '')[:160]}...")
        return data
    except Exception as e:
        print(f"Raw Output: {res_str[:300]}")
        return None

# Test Call 1: "Explain Chapter 2" with studentProfile (Class 10 CBSE) -> MUST Clarify Subject
test_api_call(
    "LIVE TEST 1: Ambiguous Chapter 2 (Class 10 CBSE) -> Clarification Required",
    {
        "messages": [{"role": "user", "content": "Explain Chapter 2"}],
        "student_id": "live_test_student_10",
        "studentProfile": {
            "class": "10",
            "board": "CBSE",
            "subjects": ["English", "Mathematics", "Science", "Social Science"]
        }
    }
)

# Test Call 2: "Explain Class 10 CBSE English Chapter 2" -> CONTENT_NOT_FOUND (Gemini NOT called)
test_api_call(
    "LIVE TEST 2: Chapter 2 Not in DB -> CONTENT_NOT_FOUND, Gemini NOT Called",
    {
        "messages": [{"role": "user", "content": "Explain Class 10 CBSE English Chapter 2"}],
        "student_id": "live_test_student_10",
        "studentProfile": {
            "class": "10",
            "board": "CBSE"
        }
    }
)

# Test Call 3: "Explain Class 10 CBSE English Chapter 1" -> RAG VALID, Gemini CALLED
test_api_call(
    "LIVE TEST 3: Chapter 1 Exists in DB -> Validated RAG, Gemini Called",
    {
        "messages": [{"role": "user", "content": "Explain Class 10 CBSE English Chapter 1"}],
        "student_id": "live_test_student_10",
        "studentProfile": {
            "class": "10",
            "board": "CBSE"
        }
    }
)

ssh.close()
print("\nVPS VERIFICATION COMPLETE!")

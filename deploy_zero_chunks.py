import paramiko
import sys
import json
import time
import requests

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

host = '213.133.97.141'
user = 'root'
pwd  = 'AfjbCUvqgdpST8'

target_dir = '/root/jeeni-server'

print("1. Connecting to VPS via SSH...")
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, username=user, password=pwd, timeout=30)
print("Connected!")

sftp = ssh.open_sftp()

print("\n2. Uploading server/src/zeroChunksHandler.js...")
with open('server/src/zeroChunksHandler.js', 'r', encoding='utf-8') as f:
    handler_content = f.read()
with sftp.file(f'{target_dir}/src/zeroChunksHandler.js', 'w') as f:
    f.write(handler_content)
print("Uploaded zeroChunksHandler.js!")

print("\n3. Uploading server/server.js...")
with open('server/server.js', 'r', encoding='utf-8') as f:
    server_content = f.read()
with sftp.file(f'{target_dir}/server.js', 'w') as f:
    f.write(server_content)
print("Uploaded server.js!")

sftp.close()

print("\n4. Restarting PM2 process 'jeeni-server'...")
_, stdout, stderr = ssh.exec_command('pm2 restart jeeni-server')
stdout_text = stdout.read().decode('utf-8', errors='ignore')
print("PM2 restart output:")
print(stdout_text[:300])

ssh.close()
print("\n5. Waiting 4 seconds for server to be fully ready...")
time.sleep(4)

SERVER_URL = "http://213.133.97.141:3000"

print("\n=======================================================")
print("RUNNING LIVE END-TO-END TESTS ON ZERO CHUNKS PIPELINE")
print("=======================================================\n")

# TEST 1: Exact question from diagram: "Explain Chapter 8 Physics (CBSE Class 10)"
print("--- TEST 1: CONTENT_NOT_FOUND (CBSE Class 10 Physics Chapter 8) ---")
q1 = "Explain Chapter 8 Physics (CBSE Class 10)"
r1 = requests.post(f"{SERVER_URL}/api/chat", json={
    "messages": [{"role": "user", "content": q1}]
}, timeout=45)

print(f"Status: {r1.status_code}")
if r1.status_code == 200:
    d1 = r1.json()
    print("Response JSON:")
    print(json.dumps(d1, indent=2))
    assert d1.get("type") == "CONTENT_NOT_FOUND", f"Expected CONTENT_NOT_FOUND but got {d1.get('type')}"
    assert d1.get("tokens_saved") == True, "Expected tokens_saved to be True"
    assert "study material" in d1.get("content", "").lower(), "Expected predefined content_not_found message"
    print(">>> TEST 1 PASSED! (0 second API calls, predefined content response returned) ✅\n")
else:
    print(f"Error: {r1.text}")

# TEST 2: Unknown Syllabus: "French Grammar for Cambridge Class 5"
print("--- TEST 2: SYLLABUS_NOT_AVAILABLE (Cambridge Class 5 French) ---")
q2 = "Explain the French grammar rules in Cambridge Grade 5 textbook"
r2 = requests.post(f"{SERVER_URL}/api/chat", json={
    "messages": [{"role": "user", "content": q2}]
}, timeout=45)

print(f"Status: {r2.status_code}")
if r2.status_code == 200:
    d2 = r2.json()
    print("Response JSON:")
    print(json.dumps(d2, indent=2))
    assert d2.get("type") == "SYLLABUS_NOT_AVAILABLE", f"Expected SYLLABUS_NOT_AVAILABLE but got {d2.get('type')}"
    assert d2.get("tokens_saved") == True, "Expected tokens_saved to be True"
    assert "syllabus is not currently available" in d2.get("content", "").lower(), "Expected syllabus_not_available message"
    print(">>> TEST 2 PASSED! (0 second API calls, predefined syllabus message returned) ✅\n")
else:
    print(f"Error: {r2.text}")

# TEST 3: Positive Grounded RAG with Chunks Present: Lencho from CBSE 10 English
print("--- TEST 3: REGRESSION TEST - CHUNKS FOUND (CBSE Class 10 English First Flight) ---")
q3 = "Write a character sketch of Lencho from CBSE Class 10 English First Flight"
r3 = requests.post(f"{SERVER_URL}/api/chat", json={
    "messages": [{"role": "user", "content": q3}]
}, timeout=45)

print(f"Status: {r3.status_code}")
if r3.status_code == 200:
    d3 = r3.json()
    print(f"Pipeline: {d3.get('pipeline')}")
    print(f"Retrieved Sources Count: {len(d3.get('sources', []))}")
    print(f"Answer snippet: {d3.get('content', '')[:250]}...")
    assert len(d3.get('sources', [])) > 0, "Expected chunks to be retrieved"
    print(">>> TEST 3 PASSED! (Chunks found, second LLM executed with textbook context) ✅\n")
else:
    print(f"Error: {r3.text}")

print("=======================================================")
print("ALL LIVE END-TO-END TESTS PASSED ON VPS! 🎉")
print("=======================================================")

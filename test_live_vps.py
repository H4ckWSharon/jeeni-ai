import paramiko, json, sys

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('213.133.97.141', username='root', password='AfjbCUvqgdpST8', timeout=30)

# Test 1: Missing Chapter 2
req1 = {
    "messages": [{"role": "user", "content": "Explain Class 10 CBSE English Chapter 2"}],
    "studentId": "vps_live_test"
}
cmd1 = f"curl -s -X POST http://localhost:3000/api/chat -H 'Content-Type: application/json' -d '{json.dumps(req1)}'"
stdin, stdout, stderr = ssh.exec_command(cmd1)
raw1 = stdout.read().decode('utf-8', errors='replace')
try:
    res1 = json.loads(raw1)
    print("--- TEST 1: Missing Chapter 2 ---")
    print("answer_source:", res1.get("answer_source"))
    print("gemini_called:", res1.get("gemini_called"))
    print("content:", res1.get("content"))
except Exception as e:
    print("Test 1 raw output:", raw1, e)

# Test 2: Ingested Chapter 1
req2 = {
    "messages": [{"role": "user", "content": "Explain Class 10 CBSE English Chapter 1"}],
    "studentId": "vps_live_test"
}
cmd2 = f"curl -s -X POST http://localhost:3000/api/chat -H 'Content-Type: application/json' -d '{json.dumps(req2)}'"
stdin, stdout, stderr = ssh.exec_command(cmd2)
raw2 = stdout.read().decode('utf-8', errors='replace')
try:
    res2 = json.loads(raw2)
    print("\n--- TEST 2: Valid Chapter 1 ---")
    print("answer_source:", res2.get("answer_source"))
    print("gemini_called:", res2.get("gemini_called"))
    print("sources count:", len(res2.get("sources", [])))
    print("content snippet:", res2.get("content", "")[:200])
except Exception as e:
    print("Test 2 raw output:", raw2, e)

ssh.close()

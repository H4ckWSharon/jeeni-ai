"""Deep inspection of VPS ChromoDB - finds actual paths and data."""
import paramiko
import sys
import json

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

host, user, pwd = '213.133.97.141', 'root', 'AfjbCUvqgdpST8'
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, username=user, password=pwd, timeout=30)

def run(cmd):
    _, out, err = ssh.exec_command(cmd, timeout=20)
    return out.read().decode('utf-8', errors='ignore'), err.read().decode('utf-8', errors='ignore')

# ChromoDB is at /root/chromodb
print("=== ChromoDB at /root/chromodb ===")
out, _ = run("ls -la /root/chromodb/")
print(out)

print("=== ChromoDB data directory ===")
out, _ = run("ls -la /root/chromodb/data/")
print(out)

print("=== Collections.json on VPS ===")
out, _ = run("cat /root/chromodb/data/collections.json")
print(out)

print("=== Document count in only collection ===")
out, _ = run("node -e \"const d=require('/root/chromodb/data/ff63aa2a-0b19-4599-95be-6bddd6d57c5a/documents.json'); console.log('Total docs:', d.length); if(d.length>0){console.log('First doc metadata:', JSON.stringify(d[0].metadata, null, 2)); console.log('Vector dimension:', d[0].vector ? d[0].vector.length : 'NO VECTOR')}\"")
print(out)

print("=== Sample of first 3 docs metadata ===")
out, _ = run("node -e \"const d=require('/root/chromodb/data/ff63aa2a-0b19-4599-95be-6bddd6d57c5a/documents.json'); d.slice(0,3).forEach((doc,i) => console.log('Doc', i+1, ':', JSON.stringify(doc.metadata)))\"")
print(out)

# Check jeeni-server .env for CHROMODB_URL
print("=== jeeni-server .env ===")
out, _ = run("cat /root/jeeni-server/.env")
print(out)

# Check chromodb .env
print("=== /root/chromodb .env ===")
out, _ = run("cat /root/chromodb/.env 2>/dev/null || echo 'no .env in /root/chromodb'")
print(out)

# Test live search
print("=== Live search test (all docs) ===")
out, _ = run("""curl -s -X POST http://localhost:4000/api/search/textbooks -H 'Content-Type: application/json' -H 'X-API-Key: jeeni_secret_vector_key_2026' -d '{"query":"character sketch Lencho","n_results":2,"threshold":0.1}' | python3 -c "import sys,json; d=json.load(sys.stdin); print('n_results:', d.get('n_results')); print('collection:', d.get('collection_name')); [print('  ->', r['metadata'].get('chunk_id', 'no_id'), r['metadata'].get('board'), r['metadata'].get('class'), r['metadata'].get('subject'), 'score:', r['score']) for r in d.get('results', [])]" """)
print(out)

print("=== Live search with board filter ===")
out, _ = run("""curl -s -X POST http://localhost:4000/api/search/textbooks -H 'Content-Type: application/json' -H 'X-API-Key: jeeni_secret_vector_key_2026' -d '{"query":"biology class 9","n_results":3,"threshold":0.1,"where":{"board":"CBSE","class":"9","subject":"Biology"}}' | python3 -c "import sys,json; d=json.load(sys.stdin); print('n_results:', d.get('n_results')); print('message:', d.get('message', ''))" """)
print(out)

ssh.close()
print("\nDone!")

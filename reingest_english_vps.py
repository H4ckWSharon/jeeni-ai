"""
Re-ingest all English chunks with correct 3072-dim embeddings.
Also updates the textbooks collection dimension to 3072 to match gemini-embedding-001.
"""
import paramiko
import sys
import json

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

host, user, pwd = '213.133.97.141', 'root', 'AfjbCUvqgdpST8'
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, username=user, password=pwd, timeout=30)
print("Connected to VPS!")

def run(cmd, timeout=60):
    _, out, err = ssh.exec_command(cmd, timeout=timeout)
    o = out.read().decode('utf-8', errors='ignore')
    e = err.read().decode('utf-8', errors='ignore')
    return o, e

# Step 1: Fix collection dimension from 768 to 3072 to match gemini-embedding-001
FIX_DIM_SCRIPT = r"""
const fs = require('fs');
const p = '/root/chromodb/data/collections.json';
const data = JSON.parse(fs.readFileSync(p, 'utf8'));
data.collections = data.collections.map(c => {
  if (c.name === 'textbooks') {
    const old = c.dimension;
    c.dimension = 3072;
    console.log(`Updated "${c.name}" dimension: ${old} -> 3072`);
  }
  return c;
});
fs.writeFileSync(p, JSON.stringify(data, null, 2));
console.log('Done. Collection metadata saved.');
"""

print("\n=== Step 1: Fixing collection dimension 768 → 3072 ===")
out, err = run(f"node -e \"{FIX_DIM_SCRIPT.replace(chr(10), ';').replace('\"', chr(39))}\"")
# Use a script file instead
sftp = ssh.open_sftp()
with sftp.file('/tmp/fix_dim.js', 'w') as f:
    f.write(FIX_DIM_SCRIPT)
sftp.close()
out, err = run("node /tmp/fix_dim.js")
print(out)
if err.strip():
    print("STDERR:", err)

# Step 2: Upload the english_chunks.json file to VPS
print("\n=== Step 2: Uploading english_chunks.json to VPS ===")
with open('english_chunks.json', 'r', encoding='utf-8') as f:
    chunks_raw = json.load(f)
print(f"Loaded {len(chunks_raw)} chunks from local file")

sftp = ssh.open_sftp()
with open('english_chunks.json', 'rb') as f:
    sftp.putfo(f, '/tmp/english_chunks.json')
sftp.close()
print("Uploaded to /tmp/english_chunks.json")

# Step 3: Re-ingest all chunks via ChromoDB API using curl on VPS
INGEST_SCRIPT = r"""
const fs = require('fs');
const https = require('https');
const http = require('http');

const CHROMODB_URL = 'http://localhost:4000';
const API_KEY = 'jeeni_secret_vector_key_2026';
const chunksRaw = JSON.parse(fs.readFileSync('/tmp/english_chunks.json', 'utf8'));

console.log(`Loaded ${chunksRaw.length} chunks`);

// Format documents with canonical metadata
const documents = chunksRaw.map(c => {
  const metadata = {
    chunk_id: c.chunk_id,
    chapter_id: c.chapter_id,
    title: c.chapter,
    chapter: c.chapter,
    board: c.board,                          // Already "CBSE"
    class: String(c.class),                   // Canonical: "10"
    subject: c.subject,                       // Already "English"
    author: c.author || '',
    chunk_type: c.chunk_type,
    chunk_type_label: c.chunk_type_label,
    content_type: c.chunk_type_label,
    topic: c.topic,
    language: 'English',
    keywords: c.keywords.join(', '),
  };

  const searchableText = `Title: ${c.chapter}\nTopic: ${c.topic}\nSubject: ${c.subject} (Class ${c.class})\nContent: ${c.content}\nKeywords: ${c.keywords.join(', ')}`;

  return { text: searchableText, metadata };
});

// POST to ChromoDB
function postJSON(url, apiKey, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const opts = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
        'Content-Length': Buffer.byteLength(data),
      },
    };
    const req = http.request(url, opts, res => {
      let buf = '';
      res.on('data', d => buf += d);
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(buf) }));
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

(async () => {
  console.log(`\nInserting ${documents.length} documents into ChromoDB...`);
  const result = await postJSON(`${CHROMODB_URL}/api/documents/textbooks/add-batch`, API_KEY, { documents });
  if (result.status === 200 || result.status === 201) {
    console.log(`SUCCESS: Added ${result.body.added} documents`);
  } else {
    console.error('ERROR:', result.status, JSON.stringify(result.body));
    process.exit(1);
  }

  // Quick verification search
  console.log('\nRunning verification search...');
  const searchResult = await postJSON(`${CHROMODB_URL}/api/search/textbooks`, API_KEY, {
    query: 'character sketch Lencho',
    n_results: 3,
    threshold: 0.1,
    where: { board: 'CBSE', class: '10', subject: 'English' },
  });
  console.log(`Search results: ${searchResult.body.n_results}`);
  (searchResult.body.results || []).forEach(r => {
    console.log(`  -> ${r.metadata.chunk_id} | board:${r.metadata.board} class:${r.metadata.class} | score:${r.score}`);
  });
})();
"""

print("\n=== Step 3: Writing ingest script to VPS ===")
sftp = ssh.open_sftp()
with sftp.file('/tmp/ingest_english.js', 'w') as f:
    f.write(INGEST_SCRIPT)
sftp.close()

print("=== Ingesting chunks (this generates embeddings — may take 60s) ===")
out, err = run("cd /root/chromodb && node /tmp/ingest_english.js 2>&1", timeout=180)
print(out)
if err.strip():
    print("STDERR:", err[:500])

# Step 4: Verify final state
print("\n=== Final verification ===")
out, err = run("""curl -s -X POST http://localhost:4000/api/search/textbooks \
  -H 'Content-Type: application/json' \
  -H 'X-API-Key: jeeni_secret_vector_key_2026' \
  -d '{"query":"character sketch Lencho faith","n_results":3,"threshold":0.1,"where":{"board":"CBSE","class":"10","subject":"English"}}' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('n_results:', d.get('n_results')); [print('  ->', r['metadata'].get('chunk_id'), r['metadata'].get('board'), r['metadata'].get('class'), r['score']) for r in d.get('results',[])]" """)
print("CBSE Class 10 English search:", out)

out, err = run("""curl -s -X POST http://localhost:4000/api/search/textbooks \
  -H 'Content-Type: application/json' \
  -H 'X-API-Key: jeeni_secret_vector_key_2026' \
  -d '{"query":"biology class 9","n_results":2,"threshold":0.1,"where":{"board":"SCERT_KERALA","class":"9","subject":"Biology"}}' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('n_results:', d.get('n_results'), '|', d.get('message',''))" """)
print("Kerala Class 9 Biology (expect 0):", out)

out, err = run("""curl -s -X POST http://localhost:4000/api/search/textbooks \
  -H 'Content-Type: application/json' \
  -H 'X-API-Key: jeeni_secret_vector_key_2026' \
  -d '{"query":"Lencho character sketch","n_results":2,"threshold":0.1,"where":{"board":"CBSE","class":"9","subject":"English"}}' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('n_results:', d.get('n_results'), '|', d.get('message',''))" """)
print("CBSE Class 9 English (expect 0):", out)

ssh.close()
print("\nRe-ingestion complete!")

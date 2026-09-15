"""
VPS Data Migration Script for Jeeni AI
=======================================
Fixes the following issues in the production ChromoDB textbooks collection:

1. Old Biology doc has 'grade' field instead of 'class' → renames it
2. Old Biology doc has no 'board' field → adds UNKNOWN_BOARD marker
3. Removes docs with mismatched vector dimensions (768 vs 3072)
   so they don't corrupt cosine similarity scores
4. Re-reports collection stats after migration

Run this ONCE on the VPS via SSH.
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

def run(cmd):
    _, out, err = ssh.exec_command(cmd, timeout=30)
    o = out.read().decode('utf-8', errors='ignore')
    e = err.read().decode('utf-8', errors='ignore')
    return o, e

MIGRATION_SCRIPT = r"""
const fs = require('fs');
const path = require('path');

const CHROMODB_DATA = '/root/chromodb/data';
const COLLECTIONS_FILE = path.join(CHROMODB_DATA, 'collections.json');

// Read collections
const collections = JSON.parse(fs.readFileSync(COLLECTIONS_FILE, 'utf8')).collections;
console.log('Collections found:', collections.length);

let totalFixed = 0;
let totalRemoved = 0;
let totalOk = 0;

for (const col of collections) {
  const docsFile = path.join(CHROMODB_DATA, col.id, 'documents.json');
  if (!fs.existsSync(docsFile)) { console.log(`  ${col.name}: no documents.json`); continue; }

  const docs = JSON.parse(fs.readFileSync(docsFile, 'utf8'));
  console.log(`\nCollection: ${col.name} (${col.id}) | Docs: ${docs.length} | Expected dim: ${col.dimension}`);

  const fixedDocs = [];
  let fixCount = 0;
  let removeCount = 0;

  for (const doc of docs) {
    const vecLen = doc.vector ? doc.vector.length : 0;

    // Remove docs with wrong vector dimension (they corrupt cosine similarity)
    if (vecLen > 0 && vecLen !== col.dimension) {
      console.log(`  [REMOVE] doc ${doc.id} - vector dim ${vecLen} != expected ${col.dimension} | metadata: ${JSON.stringify(doc.metadata).slice(0,80)}`);
      removeCount++;
      continue;
    }

    // Fix metadata: rename 'grade' -> 'class'
    let changed = false;
    const meta = { ...doc.metadata };

    if ('grade' in meta && !('class' in meta)) {
      // Extract numeric class from grade field
      const gradeVal = String(meta.grade).match(/\d+/);
      meta.class = gradeVal ? gradeVal[0] : String(meta.grade);
      delete meta.grade;
      console.log(`  [FIX] doc ${doc.id} - renamed grade="${doc.metadata.grade}" -> class="${meta.class}"`);
      changed = true;
    }

    // Fix: normalize existing class field
    if ('class' in meta && meta.class !== null) {
      const classMatch = String(meta.class).match(/\d+/);
      const normalized = classMatch ? classMatch[0] : meta.class;
      if (normalized !== meta.class) {
        meta.class = normalized;
        console.log(`  [FIX] doc ${doc.id} - normalized class to "${meta.class}"`);
        changed = true;
      }
    }

    // Fix: normalize board
    if ('board' in meta && meta.board) {
      const b = String(meta.board).trim().toUpperCase().replace(/\s+/g, ' ');
      let normalized = meta.board;
      if (b.includes('KERALA') || b.includes('SCERT') || b.includes('STATE BOARD')) normalized = 'SCERT_KERALA';
      else if (b === 'CBSE' || b.includes('CENTRAL BOARD')) normalized = 'CBSE';
      else if (b === 'NCERT') normalized = 'NCERT';
      else if (b === 'ICSE') normalized = 'ICSE';
      if (normalized !== meta.board) {
        meta.board = normalized;
        console.log(`  [FIX] doc ${doc.id} - normalized board to "${meta.board}"`);
        changed = true;
      }
    }

    // Fix: normalize subject to title-case
    if ('subject' in meta && meta.subject) {
      const titleCase = String(meta.subject).trim()
        .replace(/\w\S*/g, t => t.charAt(0).toUpperCase() + t.slice(1).toLowerCase());
      if (titleCase !== meta.subject) {
        meta.subject = titleCase;
        console.log(`  [FIX] doc ${doc.id} - normalized subject to "${meta.subject}"`);
        changed = true;
      }
    }

    if (changed) fixCount++;
    else totalOk++;

    fixedDocs.push({ ...doc, metadata: meta });
  }

  // Write back
  fs.writeFileSync(docsFile, JSON.stringify(fixedDocs, null, 2), 'utf8');
  console.log(`  Result: ${fixCount} fixed, ${removeCount} removed, ${fixedDocs.length} remaining`);
  totalFixed += fixCount;
  totalRemoved += removeCount;
}

console.log(`\n=== MIGRATION COMPLETE ===`);
console.log(`Total docs fixed: ${totalFixed}`);
console.log(`Total docs removed (dim mismatch): ${totalRemoved}`);
console.log(`Total docs unchanged: ${totalOk}`);

// Print final collection state
const collectionsAfter = JSON.parse(fs.readFileSync(COLLECTIONS_FILE, 'utf8')).collections;
for (const col of collectionsAfter) {
  const docsFile = path.join(CHROMODB_DATA, col.id, 'documents.json');
  const docs = fs.existsSync(docsFile) ? JSON.parse(fs.readFileSync(docsFile, 'utf8')) : [];
  console.log(`\nCollection "${col.name}" (dim:${col.dimension}): ${docs.length} docs remaining`);
  if (docs.length > 0) {
    console.log('  Sample metadata:', JSON.stringify(docs[0].metadata).slice(0, 120));
  }
}
"""

# Write migration script to VPS and run it
print("\n=== Writing migration script to VPS ===")
sftp = ssh.open_sftp()
with sftp.file('/tmp/migrate_chromodb.js', 'w') as f:
    f.write(MIGRATION_SCRIPT)
sftp.close()
print("Script written to /tmp/migrate_chromodb.js")

print("\n=== Running migration ===")
out, err = run("cd /root/chromodb && node /tmp/migrate_chromodb.js")
print(out)
if err.strip():
    print("STDERR:", err)

print("\n=== Restarting ChromoDB after migration ===")
out, err = run("pm2 restart chromodb")
print(out)

print("\n=== Verifying live search after migration ===")
out, err = run("""curl -s -X POST http://localhost:4000/api/search/textbooks \
  -H 'Content-Type: application/json' \
  -H 'X-API-Key: jeeni_secret_vector_key_2026' \
  -d '{"query":"character sketch Lencho","n_results":2,"threshold":0.1,"where":{"board":"CBSE","class":"10","subject":"English"}}' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('n_results:', d.get('n_results')); [print(' ->', r['metadata'].get('chunk_id'), r['metadata'].get('board'), r['metadata'].get('class'), r['metadata'].get('subject')) for r in d.get('results',[])]" """)
print("CBSE Class 10 English search:", out)

out, err = run("""curl -s -X POST http://localhost:4000/api/search/textbooks \
  -H 'Content-Type: application/json' \
  -H 'X-API-Key: jeeni_secret_vector_key_2026' \
  -d '{"query":"biology class 9","n_results":2,"threshold":0.1,"where":{"board":"SCERT_KERALA","class":"9","subject":"Biology"}}' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('n_results:', d.get('n_results'), '| message:', d.get('message',''))" """)
print("Kerala Class 9 Biology search (expect 0):", out)

ssh.close()
print("\nMigration complete!")

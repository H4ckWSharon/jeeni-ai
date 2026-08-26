import requests
import json

SERVER = "http://213.133.97.141:3000"

print("="*70)
print("TESTING FULL RAG CHAT WITH NEWLY INGESTED ENGLISH CHUNKS")
print("="*70)

r = requests.post(f"{SERVER}/api/chat", json={
    "messages": [
        {"role": "user", "content": "Write a character sketch of Lencho from CBSE Class 10 English First Flight"}
    ]
}, timeout=30)

if r.status_code == 200:
    data = r.json()
    print(f"Pipeline: {data.get('pipeline')}")
    print(f"Sources Count: {len(data.get('sources', []))}")
    for s in data.get('sources', []):
        print(f"  - Source: {s.get('title')} | Subject: {s.get('subject')} | Score: {s.get('score')}%")
        print(f"    Snippet: {s.get('snippet')}")
    print(f"\nAI Response Preview:\n{data.get('content', '')[:400]}...")
else:
    print(f"Error: {r.text}")

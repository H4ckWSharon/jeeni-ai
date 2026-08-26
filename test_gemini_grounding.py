import requests
import sys

SERVER = "http://213.133.97.141:3000"

payload = {
    "mode": "Web Search",
    "webSearch": True,
    "messages": [
        {"role": "user", "content": "What are the latest news updates about ISRO space missions and Gaganyaan today?"}
    ]
}

r = requests.post(f"{SERVER}/api/chat", json=payload, timeout=60)
print(f"Status Code: {r.status_code}")

if r.status_code == 200:
    data = r.json()
    print(f"Pipeline: {data.get('pipeline')}")
    print(f"Sources Count: {len(data.get('sources', []))}")
    for i, s in enumerate(data.get('sources', [])[:3]):
        print(f"  Source {i+1}: {s.get('title')} ({s.get('url')})")
    
    print("\n--- GROUNDED RESPONSE (encoded) ---")
    sys.stdout.buffer.write(data.get('content', '').encode('utf-8'))
    print("\n")
else:
    print(f"Error: {r.text}")

import requests
import json
import sys

SERVER = "http://213.133.97.141:3000"

payload = {
    "mode": "Web Search",
    "webSearch": True,
    "messages": [
        {"role": "user", "content": "What is the latest score of today's cricket match or latest news today?"}
    ]
}

r = requests.post(f"{SERVER}/api/chat", json=payload, timeout=60)
if r.status_code == 200:
    data = r.json()
    print("Pipeline:", data.get("pipeline"))
    print("Grounding Keys:", list(data.get("grounding", {}).keys()) if data.get("grounding") else None)
    if data.get("grounding"):
        print("webSearchQueries:", data.get("grounding", {}).get("webSearchQueries"))
        print("groundingChunks:", len(data.get("grounding", {}).get("groundingChunks", [])))
    print("Sources:", len(data.get("sources", [])))
    print("\nPreview:")
    sys.stdout.buffer.write(data.get("content", "")[:300].encode("utf-8"))
    print("\n")
else:
    print("Error:", r.text)

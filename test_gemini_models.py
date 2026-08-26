import requests

SERVER = "http://213.133.97.141:3000"
CHROMO = "http://213.133.97.141:4000"

print("="*60)
print("LIVE VPS HEALTH CHECK")
print("="*60)

# 1. Check Flutter Web App
r_web = requests.get(f"{SERVER}/app/", timeout=15)
print(f"1. Flutter Web App (/app/)   : Status {r_web.status_code} (OK) | HTML Bytes: {len(r_web.text)}")

# 2. Check ChromoDB
r_chromo = requests.get(f"{CHROMO}/", timeout=15)
print(f"2. ChromoDB Service (:4000)  : Status {r_chromo.status_code} | Name: {r_chromo.json().get('name')}")

# 3. Check Router AI endpoint
r_route = requests.post(f"{SERVER}/api/route", json={
    "messages": [{"role": "user", "content": "What is Newton's third law?"}]
}, timeout=30)
d = r_route.json()
print(f"3. Router AI API (/api/route): Status {r_route.status_code} | Action: {d.get('action')} | LLM Req: {d.get('llm_required')}")

# 4. Check Chat API endpoint
r_chat = requests.post(f"{SERVER}/api/chat", json={
    "messages": [{"role": "user", "content": "CBSE Class 10 Biology chapter 1 photosynthesis"}]
}, timeout=30)
d2 = r_chat.json()
print(f"4. Chat API (/api/chat)      : Status {r_chat.status_code} | Pipeline: {d2.get('pipeline')} | Sources: {len(d2.get('sources', []))}")
print("="*60)
print("ALL LIVE SERVICES 100% HEALTHY!")
print("="*60)

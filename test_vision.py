import requests, base64, json, sys
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

# Find the most recent large image in media storage
media_dir = r'C:\Users\sharo\.gemini\antigravity-ide\brain\37eaacc5-5b8a-4065-9988-0c8b893b091e\.tempmediaStorage'
files = sorted(Path(media_dir).glob('*.png'), key=lambda f: f.stat().st_size, reverse=True)

# Use the largest file — most likely the complex Jeeni flow diagram
best = files[0]
print(f"Testing with image: {best.name}")
print(f"File size: {best.stat().st_size // 1024}KB")

img_bytes = best.read_bytes()
b64 = base64.b64encode(img_bytes).decode()

payload = {
    "model": "gemini-2.5-flash",
    "messages": [
        {
            "role": "user",
            "content": [
                {"type": "text", "text": "Explain this image in detail. What does it show?"},
                {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{b64}"}}
            ]
        }
    ]
}

print("\nSending image to Jeeni server API...")
print("POST http://213.133.97.141:3000/api/chat")

try:
    r = requests.post(
        "http://213.133.97.141:3000/api/chat",
        json=payload,
        timeout=120
    )
    print(f"\nStatus Code: {r.status_code}")
    data = r.json()
    pipeline = data.get("pipeline", "UNKNOWN")
    sources = data.get("sources", [])
    content = data.get("content", "NO CONTENT")
    
    print(f"Pipeline: {pipeline}")
    print(f"RAG sources injected: {len(sources)} (should be 0 for image requests)")
    if sources:
        print("  WARNING: RAG was NOT skipped!")
        for s in sources:
            print(f"  - {s.get('title')} (score: {s.get('score')})")
    else:
        print("  RAG correctly SKIPPED for image request!")
    
    print(f"\nResponse length: {len(content)} chars")
    print("\n" + "="*60)
    print("JEENI VISION RESPONSE:")
    print("="*60)
    print(content[:3000])
    if len(content) > 3000:
        print(f"\n... (truncated, {len(content) - 3000} more chars)")
except Exception as e:
    print(f"ERROR: {e}")

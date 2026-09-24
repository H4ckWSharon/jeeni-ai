import requests
import json
import sys

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

BASE_URL = 'http://213.133.97.141:3000'
STUDENT_ID = 'live_sharon_test'

# 1. Setup student profile with Sharon Anil, Class 10, CBSE, Mathematics/Science
print("Setting up student profile on live VPS...")
profile_data = {
    "student_id": STUDENT_ID,
    "display_name": "Sharon Anil",
    "class": "10",
    "board": "CBSE",
    "syllabus": "NCERT",
    "subjects": ["Mathematics", "Science", "Computer Science"],
    "learning_goal": "Score 95% in Board Exams and learn AI",
    "explanation_style": "Clear, direct, and structured",
    "knowledge_level": "Intermediate",
    "personalization_enabled": True
}

r = requests.post(f"{BASE_URL}/api/profile", json=profile_data, timeout=10)
print(f"Profile setup status: {r.status_code}, response: {r.text[:100]}")

def test_query(title, query, forbidden_phrases, required_phrases=None):
    print(f"\n───────────────────────────────────────────────────────────────")
    print(f"🧪 Testing: {title}")
    print(f"Query: \"{query}\"")
    
    payload = {
        "messages": [{"role": "user", "content": query}],
        "student_id": STUDENT_ID,
        "mode": "learning"
    }
    
    try:
        res = requests.post(f"{BASE_URL}/api/chat", json=payload, timeout=30)
        if res.status_code != 200:
            print(f"❌ HTTP Error: {res.status_code} - {res.text[:200]}")
            return False
            
        data = res.json()
        reply = data.get("content", "")
        metadata = data.get("response_metadata", {})
        
        print(f"Metadata: intent={metadata.get('intent')}, mode={metadata.get('responseMode')}, path={metadata.get('responsePath')}, greetingPolicy={metadata.get('greetingPolicy')}")
        print(f"First 180 chars of reply: \"{reply[:180]}...\"")
        
        # Check forbidden phrases
        reply_lower = reply.lower()
        for forbidden in forbidden_phrases:
            if forbidden.lower() in reply_lower:
                print(f"❌ FAILED: Found forbidden phrase '{forbidden}' in reply!")
                print(f"Full reply:\n{reply}\n")
                return False
                
        # Check required phrases
        if required_phrases:
            for required in required_phrases:
                if required.lower() not in reply_lower:
                    print(f"❌ FAILED: Missing required phrase '{required}' in reply!")
                    print(f"Full reply:\n{reply}\n")
                    return False
                    
        print(f"✅ PASSED: No forbidden phrases, direct and correctly targeted response!")
        return True
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

tests = [
    (
        "Technical / Networking Query",
        "Explain TCP three-way handshake.",
        ["Hello", "Sharon", "Class 10", "Since you are", "I have access to your profile", "Your subjects are", "learning journey"],
        ["syn", "ack"]
    ),
    (
        "Code Explanation Query",
        "Explain this Python code:\ndef add(a, b):\n    return a + b",
        ["Hello", "Sharon", "Class 10", "Since you are", "Your subjects"],
        ["function", "add", "return"]
    ),
    (
        "Code Debugging Query",
        "Why does this SQL query fail: SELECT * FORM users;",
        ["Hello", "Sharon", "Class 10", "Since you are", "Your subjects"],
        ["form", "from"]
    ),
    (
        "Identity Query (Should warmly use profile)",
        "What is my name and what class am I in?",
        ["I do not know"],
        ["Sharon", "10"]
    ),
    (
        "Curriculum Missing Subject (Should ask clarification, not hallucinate)",
        "Explain Class 10 Chapter 2.",
        ["Sharon", "Hello"],
        ["subject", "which subject"]
    )
]

all_passed = True
for title, query, forbidden, required in tests:
    ok = test_query(title, query, forbidden, required)
    if not ok:
        all_passed = False

print("\n═══════════════════════════════════════════════════════════════")
if all_passed:
    print("🎉 ALL LIVE VPS TESTS PASSED PERFECTLY!")
else:
    print("❌ SOME LIVE VPS TESTS FAILED.")
print("═══════════════════════════════════════════════════════════════")

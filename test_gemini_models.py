import requests
import json
import sys

SERVER = "http://213.133.97.141:3000"

results = []

def test_route(label, message):
    r = requests.post(f"{SERVER}/api/route", json={
        "messages": [{"role": "user", "content": message}]
    }, timeout=30)
    if r.status_code == 200:
        d = r.json()
        results.append({
            "label": label,
            "action": d.get("action"),
            "intent": d.get("intent"),
            "language": d.get("language"),
            "needs_rag": d.get("retrieval", {}).get("needs_rag"),
            "needs_vision": d.get("processing", {}).get("needs_vision"),
            "needs_solver": d.get("processing", {}).get("needs_solver"),
            "confusion": d.get("processing", {}).get("confusion"),
            "widget": d.get("presentation", {}).get("widget"),
            "confidence": d.get("confidence"),
            "subject": d.get("context", {}).get("subject"),
            "topic": d.get("context", {}).get("topic"),
            "keywords": d.get("retrieval", {}).get("keywords", []),
            "depth": d.get("retrieval", {}).get("response_depth"),
            "clarification_q": d.get("clarification", {}).get("question"),
        })
    else:
        results.append({"label": label, "error": r.text[:100]})

# --- 7 Test Cases ---
test_route("1. General knowledge",          "What is the speed of light?")
test_route("2. Textbook specific",           "Explain Class 10 CBSE Chemistry chapter 5 according to my textbook")
test_route("3. Math solver",                 "Solve x^2 - 5x + 6 = 0 step by step")
test_route("4. Image analysis",              "Explain this diagram")
test_route("5. Confusion detected",          "I still don't understand. Can you explain it more simply?")
test_route("6. Clarification needed",        "Explain chapter 4")
test_route("7. Malayalam — direct answer",   "gravity enthaanu?")

# --- Print results table ---
print("\n" + "="*90)
print(f"{'#':<3} {'Label':<30} {'Action':<20} {'RAG':<5} {'Vision':<7} {'Solver':<7} {'Conf':<6} {'Widget':<20}")
print("="*90)

for r in results:
    if "error" in r:
        print(f"{'':3} {r['label']:<30} ERROR: {r['error']}")
        continue
    print(f"{r['label'][:2]:<3} {r['label'][3:30]:<30} {r['action']:<20} {str(r['needs_rag']):<5} {str(r['needs_vision']):<7} {str(r['needs_solver']):<7} {str(r['confidence']):<6} {r['widget']:<20}")

print("="*90)

# --- Detailed output for interesting cases ---
print("\n--- DETAILS ---")
for r in results:
    if "error" in r:
        continue
    print(f"\n[{r['label']}]")
    print(f"  Action   : {r['action']}")
    print(f"  Intent   : {r['intent']}")
    print(f"  Language : {r['language']}")
    print(f"  Subject  : {r['subject']} | Topic: {r['topic']}")
    print(f"  Keywords : {r['keywords']}")
    print(f"  Depth    : {r['depth']}")
    print(f"  Confusion: {r['confusion']}")
    if r['clarification_q']:
        print(f"  Clarify? : {r['clarification_q']}")

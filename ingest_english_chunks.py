import requests
import json
import sys

CHROMODB_URL = "http://213.133.97.141:4000"
API_KEY = "jeeni_secret_vector_key_2026"
HEADERS = {
    "Content-Type": "application/json",
    "X-API-Key": API_KEY
}

print("1. Loading 17 English chunks from english_chunks.json...")
with open("english_chunks.json", "r", encoding="utf-8") as f:
    chunks_raw = json.load(f)

print(f"Loaded {len(chunks_raw)} chunks successfully.")

print("\n2. Ensuring 'textbooks' collection exists in ChromoDB...")
r_col = requests.post(f"{CHROMODB_URL}/api/collections", json={"name": "textbooks"}, headers=HEADERS, timeout=10)
print(f"Collection status: {r_col.status_code}")

print("\n3. Formatting chunks for ChromoDB vector database...")
documents = []
for c in chunks_raw:
    searchable_text = f"Title: {c['chapter']}\nTopic: {c['topic']}\nSubject: {c['subject']} (Class {c['class']})\nContent: {c['content']}\nKeywords: {', '.join(c['keywords'])}"
    
    metadata = {
        "chunk_id": c["chunk_id"],
        "chapter_id": c["chapter_id"],
        "title": c["chapter"],
        "chapter": c["chapter"],
        "board": c["board"],
        "class": str(c["class"]),
        "subject": c["subject"],
        "author": c.get("author", ""),
        "chunk_type": c["chunk_type"],
        "chunk_type_label": c["chunk_type_label"],
        "content_type": c["chunk_type_label"],
        "topic": c["topic"],
        "keywords": ", ".join(c["keywords"])
    }
    
    documents.append({
        "text": searchable_text,
        "metadata": metadata
    })

print(f"Prepared {len(documents)} documents for embedding.")

print("\n4. Ingesting & generating embeddings via ChromoDB (@google/genai)...")
r_batch = requests.post(
    f"{CHROMODB_URL}/api/documents/textbooks/add-batch",
    json={"documents": documents},
    headers=HEADERS,
    timeout=180
)

print(f"Batch Ingestion Status: {r_batch.status_code}")
if r_batch.status_code in [200, 201]:
    res_data = r_batch.json()
    print(f"SUCCESS: Added {res_data.get('added', len(documents))} chunks into ChromoDB!")
else:
    print(f"Error: {r_batch.text}")
    sys.exit(1)

print("\n5. Testing Semantic Search across newly added chunks...")
test_queries = [
    ("Character sketch of Lencho", {"subject": "English"}),
    ("Non-defining relative clauses grammar explanation", {"subject": "English"}),
    ("Dust of snow poem symbolism of crow and hemlock tree", {"subject": "English"}),
    ("CBSE Class 10 English Chapter 5 summary", {"subject": "English"})
]

for query, where in test_queries:
    print(f"\nSearching: \"{query}\"")
    r_search = requests.post(
        f"{CHROMODB_URL}/api/search/textbooks",
        json={"query": query, "n_results": 2, "threshold": 0.20, "where": where},
        headers=HEADERS,
        timeout=30
    )
    if r_search.status_code == 200:
        s_data = r_search.json()
        print(f"Matches found: {s_data.get('n_results', 0)}")
        for res in s_data.get("results", []):
            m = res.get("metadata", {})
            print(f"  -> Score: {res.get('score')} | Chunk: {m.get('chunk_id')} | Label: {m.get('chunk_type_label')} | Topic: {m.get('topic')}")
    else:
        print(f"Search Error: {r_search.text}")

print("\nALL 17 CHUNKS EMBEDDED AND SAVED TO CHROMODB SUCCESSFULLY!")

import os
import uuid
from qdrant_client import QdrantClient
from qdrant_client.http.models import PointStruct
import requests

# Setup Environment
gemini_api_key = os.getenv("GEMINI_API_KEY")

if not gemini_api_key:
    print("Error: GEMINI_API_KEY is missing.")
    exit(1)

# Initialize Clients
qdrant = QdrantClient(path="qdrant_data")

from qdrant_client.http.models import VectorParams, Distance

COLLECTION_NAME = "medical_literature_db"

try:
    qdrant.delete_collection(COLLECTION_NAME)
    print("Deleted old collection.")
except:
    pass

print("Creating collection...")
qdrant.create_collection(
    collection_name=COLLECTION_NAME,
    vectors_config=VectorParams(size=3072, distance=Distance.COSINE),
)

def chunk_text(text, chunk_size=300):
    words = text.split()
    for i in range(0, len(words), chunk_size):
        yield " ".join(words[i:i + chunk_size])

def main():
    print("Reading dummy_data.txt...")
    try:
        with open("dummy_data.txt", "r") as f:
            text = f.read()
    except Exception as e:
        print(f"Error reading file: {e}")
        return

    print("Chunking text...")
    chunks = list(chunk_text(text))
    
    print(f"Embedding {len(chunks)} chunks using Google GenAI...")
    points = []
    for i, chunk in enumerate(chunks):
        # We use gemini-embedding-2 via REST API
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-2:embedContent?key={gemini_api_key}"
        response = requests.post(url, json={
            "model": "models/gemini-embedding-2",
            "content": {
                "parts": [{"text": chunk}]
            }
        })
        
        if response.status_code != 200:
            print(f"Error embedding chunk {i}: {response.text}")
            continue
            
        embedding = response.json()["embedding"]["values"]
        
        point_id = str(uuid.uuid4())
        points.append(
            PointStruct(
                id=point_id,
                vector=embedding,
                payload={"text": chunk, "source": "dummy_data.txt", "chunk_index": i}
            )
        )
        
    print("Upserting vectors into Qdrant...")
    qdrant.upsert(
        collection_name=COLLECTION_NAME,
        points=points
    )
    print("Ingestion complete!")

if __name__ == "__main__":
    main()

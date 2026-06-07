import os
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams

def init_collections():
    print("Initializing Qdrant...")
    client = QdrantClient(path="qdrant_data")

    collections = [
        "medical_literature_db",
        "patient_case_history_db"
    ]

    # Google Gemini text-embedding-004 vector size is typically 768. 
    # We will use 768 as the default vector size.
    VECTOR_SIZE = 768

    for collection_name in collections:
        if not client.collection_exists(collection_name):
            print(f"Creating collection: {collection_name}")
            client.create_collection(
                collection_name=collection_name,
                vectors_config=VectorParams(size=VECTOR_SIZE, distance=Distance.COSINE),
            )
            print(f"Successfully created {collection_name}.")
        else:
            print(f"Collection {collection_name} already exists. Skipping.")

if __name__ == "__main__":
    init_collections()

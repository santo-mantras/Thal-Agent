# 🩸 CareMate AI — Thalassemia Care Assistant

<div align="center">

![CareMate AI](https://img.shields.io/badge/CareMate-AI-teal?style=for-the-badge&logo=medrt&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-Web-blue?style=for-the-badge&logo=flutter)
![Python](https://img.shields.io/badge/Python-3.11-yellow?style=for-the-badge&logo=python)
![FastAPI](https://img.shields.io/badge/FastAPI-0.100-green?style=for-the-badge&logo=fastapi)
![Qdrant](https://img.shields.io/badge/Qdrant-Vector%20DB-red?style=for-the-badge)
![Docker](https://img.shields.io/badge/Docker-Containerized-blue?style=for-the-badge&logo=docker)

**CareMate AI** is an advanced AI healthcare assistant specializing in Thalassemia management — designed to empower patients with chronic care tracking and assist doctors with clinical insights.

</div>

---

## 🌟 What Is CareMate AI?

CareMate AI combines a **Retrieval-Augmented Generation (RAG)** pipeline with **Google Gemini LLM** to provide:

- 🔍 Intelligent medical research based on up-to-date Thalassemia literature
- 📈 Automated extraction of Hemoglobin & Ferritin levels from uploaded medical reports
- 🧑‍⚕️ Dual-Persona portals tailored specifically for **Patients** and **Doctors**
- 📅 Interactive health timelines and medical records tracking
- 💾 Persistent patient profiles and chat memory

---

## 🚀 Live Demo

| Environment | URL |
|---|---|
| **Production** | [https://huggingface.co/spaces/SeriousSam07/thalassemia-agent](https://huggingface.co/spaces/SeriousSam07/thalassemia-agent) |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **LLM** | Google Gemini (1.5 Flash & Pro) |
| **AI Orchestration** | LangChain & Custom Agents |
| **RAG / Vector DB** | Qdrant (Local Mode) + Gemini Embeddings |
| **Backend** | FastAPI + Uvicorn |
| **Database** | SQLite (User profiles, Timelines, Auth) |
| **Frontend** | Flutter Web (Dart) |
| **Containerization** | Docker (Multi-stage build) |
| **Hosting** | Hugging Face Spaces |

---

## 🏗️ Architecture Overview

```mermaid
graph TB
    User["👤 Patient / Doctor"]
    Frontend["📱 Flutter Web UI<br/>(Static Assets)"]
    FastAPI["🔌 FastAPI Server<br/>REST API & Static Hosting"]
    
    AgentOrchestrator["🤖 AI Agents<br/>Intake / Logic / Comm"]
    
    QdrantDB["📚 Qdrant Vector DB<br/>Medical Literature"]
    SQLite["💾 SQLite Database<br/>Profiles & Timelines"]
    LLM["🧠 Google Gemini API"]
    
    User -->|Interacts| Frontend
    Frontend -->|HTTP Requests| FastAPI
    
    FastAPI -->|DB Queries| SQLite
    FastAPI -->|AI Tasks| AgentOrchestrator
    
    AgentOrchestrator -->|Search| QdrantDB
    AgentOrchestrator -->|Prompt| LLM
    
    QdrantDB -.->|Context| AgentOrchestrator
    LLM -.->|Response| AgentOrchestrator
    
    AgentOrchestrator -.->|JSON| FastAPI
    FastAPI -.->|Data| Frontend
```

### Data Flow Diagram

```mermaid
graph LR
    UserMsg["💬 User Query / Upload"]
    API["🔌 FastAPI Router"]
    Extractor["📄 OCR & Intake Agent"]
    Logic["⚙️ Medical Logic Agent"]
    RAG["📚 Qdrant RAG"]
    Comm["🗣️ Persona Router (Flash)"]
    DB["💾 SQLite Store"]
    
    UserMsg --> API
    API --> Extractor
    Extractor --> Logic
    API --> RAG
    RAG --> Logic
    Logic --> Comm
    Comm --> DB
    Comm --> Output["✅ Final Response"]
```

---

## ✨ Key Features

### 1. 🧑‍⚕️ Dual-Persona Portals
The app intelligently routes the user interface and AI responses based on the logged-in role:
- **Patient Portal:** Simplified medical terms, empathetic AI tone, graphical timeline of health, and automated extraction of lab reports.
- **Doctor Portal:** Deep clinical insights, access to medical literature via RAG, patient search, and professional medical terminology.

### 2. 📚 RAG Pipeline (Medical Knowledge)
- Uses Qdrant to store embeddings of up-to-date Thalassemia medical literature and guidelines.
- The AI securely searches this database before answering clinical queries to avoid hallucinations.

### 3. 📄 Automated Report Analysis
- Upload complete medical reports (PDF/TXT).
- The **Intake Agent** automatically parses the text, extracting critical values like Hemoglobin and Serum Ferritin.

### 4. 📈 Interactive Health Timeline
- A visual timeline dashboard for patients.
- Tracks major events like Blood Transfusions, Chelation Therapy, and Lab Results.

---

## 📁 Project Structure

```text
/
├── Dockerfile                  # Multi-stage container definition
├── README.md                   # This file
├── docker-compose.yml          # Local orchestration
├── backend/
│   ├── main.py                 # FastAPI application
│   ├── models.py               # SQLAlchemy database models
│   ├── schemas.py              # Pydantic validation schemas
│   ├── agent.py                # AI Agent definitions
│   ├── ingest.py               # Script to ingest data to Qdrant
│   ├── upload_analyzer.py      # OCR & Gemini Vision logic
│   └── thal_app.sqlite         # SQLite database
├── frontend/
│   ├── pubspec.yaml            # Flutter dependencies
│   └── lib/
│       ├── main.dart           # App entry point & Routing
│       ├── patient_portal.dart # Patient UI
│       ├── doctor_portal.dart  # Doctor UI
│       └── api_service.dart    # Backend connection logic
└── qdrant_data/                # Local Vector DB storage
```

---

## ⚙️ Environment Variables

The app requires the following secret to function properly.

| Variable | Description |
|---|---|
| GEMINI_API_KEY | Google Gemini API key used for all AI and Embedding tasks. |

> ⚠️ **Note:** On Hugging Face Spaces, this must be set in the Settings > Secrets panel.

---

## 🐳 Running Locally

```bash
# 1. Clone the repo
git clone https://github.com/santo-mantras/Thal-Agent.git
cd Thal-Agent

# 2. Run with Docker Compose
docker-compose up --build

# 3. Open in browser
# http://localhost:8000
```

---

## 📜 License

This project is for educational and research purposes. All medical advice is AI-generated and should be verified by a qualified medical professional before clinical application.

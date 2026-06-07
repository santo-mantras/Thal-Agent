# Thalassemia AI Assistant

Welcome to the Thalassemia AI Assistant! This is a full-stack, AI-powered healthcare application built to assist both **Patients** and **Doctors** in managing Thalassemia treatment, timelines, and medical knowledge.

## Architecture Overview

1. **Frontend (Flutter Web)**:
   - A beautiful, responsive user interface built using **Flutter**.
   - Handles multi-role routing (Patient Portal vs. Doctor Portal vs. Admin Dashboard).

2. **Backend (FastAPI - Python)**:
   - A high-performance REST API built with **FastAPI**.
   - Handles user authentication, data management, file uploads, and AI orchestration.
   - Serves the Flutter Web assets natively via static routing.

3. **AI Agent & RAG (LangChain & Qdrant)**:
   - **LangChain**: Orchestrates the AI workflows, prompt management, and document processing.
   - **Qdrant**: A high-performance local vector database running alongside the app to store dense embeddings of medical literature.

4. **Relational Database (SQLite)**:
   - Manages all structured relational data (Users, Timelines, Chat history).

## Hosting on Hugging Face Spaces

This application is deployed on a **Docker Space** within Hugging Face.

### How the Container Works
The environment is managed using a multi-stage Dockerfile:
- **Stage 1 (Build)**: The Flutter SDK builds the web frontend.
- **Stage 2 (Serve)**: A slim Python environment installs FastAPI and AI dependencies, copies the built Flutter assets, and serves the API and web UI from port 7860.

### Data Notes
Hugging Face Spaces run as ephemeral Docker containers. By default, Hugging Face ignores *.db files. To bypass this, our SQLite database is explicitly saved as 	hal_app.sqlite to ensure the initial data payload is properly mounted.

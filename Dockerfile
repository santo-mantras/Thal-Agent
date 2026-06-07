# Stage 1: Build Flutter Web
FROM debian:bookworm-slim AS build-env

# Install dependencies for Flutter
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Setup Flutter (Stable channel)
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
# Force tar to not try preserving ownership (fixes HF Spaces build error)
ENV TAR_OPTIONS="--no-same-owner"
RUN flutter doctor -v

# Copy frontend source
WORKDIR /app/frontend
COPY frontend/ .

# Enable web and build the static files
RUN flutter config --enable-web
RUN flutter build web --release

# Stage 2: Setup Python & Serve with FastAPI
FROM python:3.10-slim

WORKDIR /app

# Install system dependencies for OCR/OpenCV (used by rapidocr)
RUN apt-get update && apt-get install -y libgl1 libglib2.0-0

# Install Python requirements
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source
COPY backend/ .

# Copy built flutter files into the 'static' folder for FastAPI to serve
COPY --from=build-env /app/frontend/build/web static/

# Ensure uploads and local Qdrant directory exists
RUN mkdir -p uploads
RUN mkdir -p qdrant_data

# Expose port 7860 (Hugging Face Default)
EXPOSE 7860

# Run FastAPI (Serving API and Static files on same port)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]

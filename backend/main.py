from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
import os
import time
import requests
from pydantic import BaseModel
from typing import List, Optional

from database import engine, get_db
import models
import schemas
import crud
from qdrant_client import QdrantClient
import upload_analyzer

# Create tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Thalassemia AI Assistant Backend")

os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Enable CORS for Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def read_root():
    return {"status": "healthy", "service": "Thalassemia AI Backend"}

# --- AUTH & USERS ---
@app.post("/users/", response_model=schemas.UserResponse)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_username(db, username=user.username)
    if db_user:
        return db_user # return existing
    return crud.create_user(db=db, user=user)

# --- ADMIN ENDPOINTS ---
@app.get("/admin/users")
def get_all_users(db: Session = Depends(get_db)):
    users = crud.get_all_users(db)
    result = []
    for u in users:
        data = {"id": u.id, "username": u.username, "role": u.role, "name": "Unknown"}
        if u.role == "patient" and u.patient_record:
            data["name"] = u.patient_record.name
            data["age"] = u.patient_record.age
        elif u.role == "doctor" and u.doctor_profile:
            data["name"] = u.doctor_profile.name
            data["specialty"] = u.doctor_profile.specialty
        result.append(data)
    return result

@app.delete("/admin/users/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db)):
    success = crud.delete_user(db, user_id)
    if not success:
        raise HTTPException(status_code=404, detail="User not found")
    return {"message": "User deleted successfully"}

@app.put("/admin/users/{user_id}")
def update_user(user_id: int, updates: dict, db: Session = Depends(get_db)):
    success = crud.update_user_profile(db, user_id, updates)
    if not success:
        raise HTTPException(status_code=404, detail="User not found")
    return {"message": "User updated successfully"}

@app.get("/users/{username}", response_model=schemas.UserResponse)
def get_user(username: str, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_username(db, username=username)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user

# --- PATIENT PROFILES ---
def to_patient_response(db_record, db: Session):
    if db_record is None:
        return None
    resp = schemas.PatientRecordResponse.from_orm(db_record)
    if db_record.doctor_id:
        doc = crud.get_doctor_profile(db, db_record.doctor_id)
        if doc:
            resp.doctor_name = doc.name
    return resp

@app.post("/patients/{user_id}", response_model=schemas.PatientRecordResponse)
def create_patient_record(user_id: int, record: schemas.PatientRecordCreate, db: Session = Depends(get_db)):
    db_record = crud.get_patient_record(db, user_id=user_id)
    if db_record:
        db_record = crud.update_patient_record(db, user_id, record.dict(exclude_unset=True))
    else:
        db_record = crud.create_patient_record(db=db, record=record, user_id=user_id)
    return to_patient_response(db_record, db)

@app.get("/patients/{user_id}", response_model=schemas.PatientRecordResponse)
def get_patient_record(user_id: int, db: Session = Depends(get_db)):
    db_record = crud.get_patient_record(db, user_id=user_id)
    if db_record is None:
        raise HTTPException(status_code=404, detail="Patient record not found")
    return to_patient_response(db_record, db)

@app.get("/patients/search/", response_model=List[schemas.PatientRecordResponse])
def search_patients(query: str, db: Session = Depends(get_db)):
    # Simple search by name (case-insensitive)
    records = db.query(models.PatientRecord).filter(models.PatientRecord.name.ilike(f"%{query}%")).all()
    return [to_patient_response(r, db) for r in records]

@app.put("/patients/{user_id}/notes", response_model=schemas.PatientRecordResponse)
def update_patient_notes(user_id: int, notes: schemas.PatientRecordUpdateNotes, db: Session = Depends(get_db)):
    db_record = crud.update_patient_record(db, user_id=user_id, updates=notes.dict(exclude_unset=True))
    if db_record is None:
        raise HTTPException(status_code=404, detail="Patient record not found")
    return to_patient_response(db_record, db)

class AssignDoctorReq(BaseModel):
    doctor_id: int

@app.put("/patients/{user_id}/doctor", response_model=schemas.PatientRecordResponse)
def assign_doctor(user_id: int, req: AssignDoctorReq, db: Session = Depends(get_db)):
    db_record = crud.update_patient_record(db, user_id=user_id, updates={"doctor_id": req.doctor_id})
    if db_record is None:
        raise HTTPException(status_code=404, detail="Patient record not found")
    return to_patient_response(db_record, db)

# --- DOCTOR PROFILES ---
@app.post("/doctors/{user_id}", response_model=schemas.DoctorProfileResponse)
def create_doctor_profile(user_id: int, profile: schemas.DoctorProfileCreate, db: Session = Depends(get_db)):
    return crud.create_doctor_profile(db=db, profile=profile, user_id=user_id)

@app.get("/doctors/{user_id}", response_model=schemas.DoctorProfileResponse)
def get_doctor_profile(user_id: int, db: Session = Depends(get_db)):
    db_profile = crud.get_doctor_profile(db, user_id=user_id)
    if db_profile is None:
        raise HTTPException(status_code=404, detail="Doctor profile not found")
    return db_profile

# --- CHAT SESSIONS ---
@app.post("/chat/{user_id}", response_model=schemas.ChatSessionResponse)
def save_chat_session(user_id: int, session: schemas.ChatSessionCreate, db: Session = Depends(get_db)):
    return crud.create_chat_session(db=db, user_id=user_id, messages=session.messages)

@app.get("/chat/{user_id}", response_model=List[schemas.ChatSessionResponse])
def get_chat_sessions(user_id: int, db: Session = Depends(get_db)):
    return crud.get_chat_sessions(db, user_id=user_id)

# --- VISIT RECORDS ---
class VisitReq(BaseModel):
    doctor_id: int
    date: str
    doctor_notes: Optional[str] = None
    prescription: Optional[str] = None
    hb: Optional[float] = None
    ferritin: Optional[float] = None
    weight: Optional[float] = None
    bp: Optional[str] = None

@app.post("/patients/{user_id}/visits", response_model=schemas.VisitRecordResponse)
def add_visit_record(user_id: int, req: VisitReq, db: Session = Depends(get_db)):
    v_create = schemas.VisitRecordCreate(
        date=req.date,
        doctor_notes=req.doctor_notes,
        prescription=req.prescription,
        hb=req.hb,
        ferritin=req.ferritin,
        weight=req.weight,
        bp=req.bp
    )
    return crud.create_visit_record(db, record=v_create, patient_id=user_id, doctor_id=req.doctor_id)

@app.get("/patients/{user_id}/visits", response_model=List[schemas.VisitRecordResponse])
def get_visit_records(user_id: int, db: Session = Depends(get_db)):
    return crud.get_visit_records(db, patient_id=user_id)

@app.post("/upload-report/{user_id}")
async def upload_medical_report(
    user_id: int,
    file: UploadFile = File(...),
    report_type: str = Form(...),
    is_own_report: str = Form(...),
    db: Session = Depends(get_db)
):
    patient_record = crud.get_patient_record(db, user_id)
    user_name = patient_record.name if patient_record else "Unknown"
    
    file_bytes = await file.read()
    raw_text = upload_analyzer.extract_text_from_bytes(file_bytes, file.filename)
    if "Error" in raw_text:
        raise HTTPException(status_code=400, detail=raw_text)
        
    verified, anonymized_text = upload_analyzer.verify_and_anonymize(raw_text, user_name)
    
    if is_own_report == "Own Report" and not verified:
        return {"status": "failed", "message": "Ownership Verification Failed: We could not find your name in the report text."}
        
    data = upload_analyzer.analyze_report_with_gemini(anonymized_text, report_type, is_own_report)
    if "error" in data:
        raise HTTPException(status_code=500, detail=data["error"])
        
    # Save file
    safe_filename = f"{int(time.time())}_{file.filename}"
    file_path = os.path.join("uploads", safe_filename)
    with open(file_path, "wb") as f:
        f.write(file_bytes)

    try:
        report_data = {
            "patient_user_id": user_id if is_own_report == "Own Report" else None,
            "uploader_user_id": user_id,
            "date": data.get("date") if data.get("date") else "Unknown",
            "report_type": report_type,
            "file_path": file_path,
            "analysis_summary": data.get("summary"),
            "is_own_report": is_own_report
        }
        crud.create_medical_report(db, report_data)

        if is_own_report != "Own Report":
            return {"status": "success", "message": "Report analyzed successfully. (Timeline NOT updated).", "data": data}

        if data.get("date") or data.get("hb") or data.get("ferritin"):
            updates = {}
            if data.get("hb") is not None: updates["latest_hb"] = data["hb"]
            if data.get("ferritin") is not None: updates["latest_ferritin"] = data["ferritin"]
            if data.get("weight") is not None: updates["weight"] = data["weight"]
            if data.get("platelets") is not None: updates["platelets"] = data["platelets"]
            if data.get("bp") is not None: updates["bp"] = data["bp"]
            
            if updates and patient_record:
                crud.update_patient_record(db, user_id, updates)
                
            v_create = schemas.VisitRecordCreate(
                date=data.get("date") if data.get("date") else "Unknown",
                doctor_notes=data.get("doctor_notes") if data.get("doctor_notes") else f"Auto-extracted from {report_type} upload",
                prescription="",
                hb=data.get("hb"),
                ferritin=data.get("ferritin"),
                weight=data.get("weight"),
                bp=data.get("bp")
            )
            doc_id = patient_record.doctor_id if patient_record and patient_record.doctor_id else 1
            crud.create_visit_record(db, record=v_create, patient_id=user_id, doctor_id=doc_id)
            
            return {"status": "success", "message": "Report verified. Data updated.", "data": data}
        else:
            return {"status": "partial", "message": "Processed but no key biomarkers found.", "data": data}
    except Exception as e:
        return {"status": "error", "message": f"Database error: {str(e)}"}

@app.get("/patients/{user_id}/reports", response_model=List[schemas.MedicalReportResponse])
def get_patient_reports(user_id: int, db: Session = Depends(get_db)):
    return crud.get_medical_reports(db, patient_id=user_id)

# --- AI & RAG ENDPOINTS ---
class AskData(BaseModel):
    query: str
    context: Optional[str] = None # Used to pass patient records as context
    chat_history: Optional[List[dict]] = None

@app.post("/ask-with-file")
async def ask_question_with_file(
    file: UploadFile = File(...),
    query: str = Form(...),
    chat_history: str = Form(...) # JSON string
):
    try:
        file_bytes = await file.read()
        extracted_text = upload_analyzer.extract_text_from_bytes(file_bytes, file.filename)
        
        # Parse chat history from string
        import json
        history_list = []
        if chat_history and chat_history != "null" and chat_history != "":
            try:
                history_list = json.loads(chat_history)
            except:
                pass
                
        # Now use the same AskData format to pass to Gemini
        augmented_query = f"User uploaded a file named '{file.filename}'.\n\nExtracted File Content:\n{extracted_text}\n\nUser Question:\n{query}"
        ask_data = AskData(query=augmented_query, context=None, chat_history=history_list)
        return ask_question(ask_data)
    except Exception as e:
        return {"answer": f"Backend Error processing file: {str(e)}"}

@app.post("/ask")
def ask_question(data: AskData):
    gemini_api_key = os.getenv("GEMINI_API_KEY")
    if not gemini_api_key:
        return {"answer": "Error: GEMINI_API_KEY not found."}

    # 1. Embed the query
    import time
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-2:embedContent?key={gemini_api_key}"
    
    embed_retries = 3
    embed_delay = 5
    for attempt in range(embed_retries):
        resp = requests.post(url, json={
            "model": "models/gemini-embedding-2",
            "content": {"parts": [{"text": data.query}]}
        })
        
        if resp.status_code == 429:
            if attempt < embed_retries - 1:
                time.sleep(embed_delay)
                embed_delay *= 2
                continue
            else:
                return {"answer": "Embedding API is currently receiving too many requests. Please try again."}
                
        if resp.status_code != 200:
            return {"answer": f"Embedding error: {resp.text}"}
            
        break
        
    embedding = resp.json()["embedding"]["values"]

    # 2. Search Qdrant
    try:
        # Use Local Mode for Hugging Face Spaces compatibility
        client = QdrantClient(path="qdrant_data")
        search_result = client.query_points(
            collection_name="medical_literature_db",
            query=embedding,
            limit=2
        ).points
        literature_context = "\n\n".join([hit.payload["text"] for hit in search_result])
    except Exception as e:
        literature_context = "Could not connect to medical literature database."

    # 3. Call Gemini
    rag_instructions = (
        "You are an expert Thalassemia Medical AI Assistant. "
        "You help Patients, Doctors, and General Users with friendly, empathetic, and highly accurate advice. "
        "Use the provided medical literature to answer clinical questions. "
        "Use the user's personal context (if provided) to personalize your response. "
        "CRITICAL RULES FOR RESPONSES: "
        "1. ALWAYS KEEP YOUR RESPONSES EXTREMELY SHORT (Maximum 2-3 sentences). "
        "2. NEVER dump a wall of text or a long list of bullet points. "
        "3. Focus on ONE topic or question at a time. "
        "4. Keep it engaging, but DO NOT always ask 'How are you feeling today?' - vary your conversational tone. "
        "5. IMPORTANT FERRITIN GUIDELINE: Serum Ferritin should be tested every 3 months for patients on regular transfusions. The goal is to maintain Ferritin < 1000 ng/mL. "
        "6. Highlight critical terms (like Hb levels, medications, or urgency) using **bold** markdown so they stand out."
    )

    prompt = ""
    if data.context:
        prompt += f"User Profile Context:\n{data.context}\n\n"
        
    if data.chat_history:
        prompt += "--- Previous Conversation History ---\n"
        # Include last 10 messages for context
        for msg in data.chat_history[-10:]:
            role = msg.get("role", "user").upper()
            text = msg.get("text", "")
            prompt += f"{role}: {text}\n"
        prompt += "-------------------------------------\n\n"
    
    prompt += f"Medical Literature:\n{literature_context}\n\nCurrent Question:\n{data.query}"
    
    import time
    
    gen_url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key={gemini_api_key}"
    
    max_retries = 3
    retry_delay = 5
    
    for attempt in range(max_retries):
        gen_resp = requests.post(gen_url, json={
            "contents": [{"parts": [{"text": prompt}]}],
            "systemInstruction": {"parts": [{"text": rag_instructions}]}
        })
        
        if gen_resp.status_code == 429:
            if attempt < max_retries - 1:
                time.sleep(retry_delay)
                retry_delay *= 2  # Exponential backoff
                continue
            else:
                return {"answer": "I am currently receiving too many requests. Please wait a minute and try again."}
                
        if gen_resp.status_code != 200:
            try:
                error_data = gen_resp.json()
                if error_data.get("error", {}).get("code") == 503:
                    return {"answer": "I'm currently experiencing high demand and need a quick breather. Please try asking again in a moment!"}
                return {"answer": f"API Error: {error_data.get('error', {}).get('message', 'Unknown error')}"}
            except:
                return {"answer": "I encountered an unexpected error processing your request. Please try again."}

        # Success
        break

    answer = gen_resp.json()["candidates"][0]["content"]["parts"][0]["text"]
    
    return {"answer": answer}

class ResearchQuery(BaseModel):
    query: str
    source: str # "pubmed", "clinicaltrials", "openfda"

def search_ct(query):
    # ClinicalTrials.gov API v2
    url = f"https://clinicaltrials.gov/api/v2/studies?query.cond=Thalassemia&query.term={query}&filter.overallStatus=RECRUITING&pageSize=5"
    try:
        resp = requests.get(url).json()
        studies = resp.get("studies", [])
        results = []
        for s in studies:
            protocol = s.get("protocolSection", {})
            ident = protocol.get("identificationModule", {})
            status = protocol.get("statusModule", {})
            results.append({
                "title": ident.get("officialTitle", "No Title"),
                "nctId": ident.get("nctId", ""),
                "status": status.get("overallStatus", "Unknown"),
                "link": f"https://clinicaltrials.gov/study/{ident.get('nctId', '')}"
            })
        return results
    except Exception: return []

def search_fda(query):
    # OpenFDA API for drug adverse events
    url = f"https://api.fda.gov/drug/event.json?search=patient.drug.medicinalproduct:{query}&limit=5"
    try:
        resp = requests.get(url).json()
        events = resp.get("results", [])
        results = []
        for e in events:
            patient = e.get("patient", {})
            reactions = patient.get("reaction", [])
            reaction_terms = [r.get("reactionmeddrapt", "") for r in reactions[:3]]
            results.append({
                "serious": e.get("serious", "2") == "1",
                "reactions": ", ".join(reaction_terms),
                "title": f"Adverse Event for {query}",
                "link": "https://open.fda.gov/"
            })
        return results
    except Exception: return []

def search_pm(query):
    # PubMed E-utilities search
    url = f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=Thalassemia+{query}&retmode=json&retmax=5"
    try:
        resp = requests.get(url).json()
        idlist = resp.get("esearchresult", {}).get("idlist", [])
        if not idlist: return []
        summary_url = f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id={','.join(idlist)}&retmode=json"
        sum_resp = requests.get(summary_url).json()
        results = []
        for pmid in idlist:
            doc = sum_resp.get("result", {}).get(pmid, {})
            results.append({
                "title": doc.get("title", ""),
                "pubdate": doc.get("pubdate", ""),
                "authors": [a.get("name", "") for a in doc.get("authors", [])[:2]],
                "pmid": pmid,
                "link": f"https://pubmed.ncbi.nlm.nih.gov/{pmid}/"
            })
        return results
    except Exception: return []

@app.post("/research")
def search_medical_research(data: ResearchQuery):
    if data.source == "clinicaltrials":
        return {"results": search_ct(data.query)}
    elif data.source == "openfda":
        return {"results": search_fda(data.query)}
    elif data.source == "pubmed":
        return {"results": search_pm(data.query)}
    elif data.source == "all":
        res = []
        res.extend(search_pm(data.query))
        res.extend(search_ct(data.query))
        res.extend(search_fda(data.query))
        return {"results": res}
    return {"results": [], "error": "Invalid source"}

# --- STATIC FILES SERVING (Hugging Face Compatibility) ---
# Ensure this is at the VERY BOTTOM so it doesn't override API routes.

# Create static directory if it doesn't exist
os.makedirs("static", exist_ok=True)

# Mount the static directory to serve assets
app.mount("/assets", StaticFiles(directory="static/assets"), name="flutter_assets") if os.path.exists("static/assets") else None

@app.get("/{full_path:path}")
async def serve_spa(full_path: str):
    static_path = os.path.join("static", full_path)
    if os.path.exists(static_path) and os.path.isfile(static_path):
        return FileResponse(static_path)
    
    index_path = os.path.join("static", "index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path)
    
    return {"message": "API is running. Flutter UI not built yet. (HF Single Container Mode)"}

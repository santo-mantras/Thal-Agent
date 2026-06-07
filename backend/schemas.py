from pydantic import BaseModel, Field
from typing import Optional, List

class UserCreate(BaseModel):
    username: str
    role: str

class UserResponse(BaseModel):
    id: int
    username: str
    role: str

    class Config:
        from_attributes = True

class PatientRecordCreate(BaseModel):
    name: str
    age: int
    sex: str
    is_married: Optional[bool] = False
    has_children: Optional[bool] = False
    partner_thalassemic: Optional[str] = "No"

    thalassemia_type: Optional[str] = None
    blood_transfusion_volume: Optional[str] = None
    blood_transfusion_frequency: Optional[str] = None
    last_transfusion_date: Optional[str] = None
    next_transfusion_date: Optional[str] = None
    spleen_removed: Optional[bool] = False
    spleen_removed_date: Optional[str] = None

    latest_hb: Optional[float] = None
    date_hb_test: Optional[str] = None
    latest_ferritin: Optional[float] = None
    date_ferritin_test: Optional[str] = None
    latest_t2_mri: Optional[float] = None
    date_t2_mri: Optional[str] = None
    height: Optional[float] = None
    weight: Optional[float] = None
    bp: Optional[str] = None
    sugar: Optional[float] = None
    bmi: Optional[float] = None
    platelets: Optional[float] = None
    other_tests: Optional[str] = None

    city: Optional[str] = None
    state: Optional[str] = None
    hospital_city: Optional[str] = None
    hospital_state: Optional[str] = None
    hospital_type: Optional[str] = None
    transfusion_cost: Optional[str] = None
    medicine_cost: Optional[str] = None
    other_costs: Optional[str] = None

    medicines: Optional[str] = None
    medicine_adherence: Optional[str] = None

    doctor_notes: Optional[str] = None
    prescription: Optional[str] = None

class PatientRecordUpdateNotes(BaseModel):
    name: Optional[str] = None
    doctor_notes: Optional[str] = None
    prescription: Optional[str] = None
    thalassemia_type: Optional[str] = None
    height: Optional[float] = None
    weight: Optional[float] = None
    bp: Optional[str] = None
    sugar: Optional[float] = None
    bmi: Optional[float] = None
    platelets: Optional[float] = None
    latest_hb: Optional[float] = None
    latest_ferritin: Optional[float] = None
    next_transfusion_date: Optional[str] = None

class PatientRecordResponse(PatientRecordCreate):
    id: int
    user_id: int
    doctor_id: Optional[int] = None
    doctor_name: Optional[str] = None

    class Config:
        from_attributes = True

class DoctorProfileCreate(BaseModel):
    name: str
    specialty: str
    experience_years: int
    hospital_name: Optional[str] = None
    age: Optional[int] = None
    sex: Optional[str] = None
    patient_load: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None

class DoctorProfileResponse(DoctorProfileCreate):
    id: int
    user_id: int

    class Config:
        from_attributes = True

class ChatMessage(BaseModel):
    role: str # "user" or "agent"
    text: str

class ChatSessionCreate(BaseModel):
    messages: str # JSON string of messages

class ChatSessionResponse(BaseModel):
    id: int
    user_id: int
    messages: str
    created_at: str

    class Config:
        from_attributes = True

class AskData(BaseModel):
    query: str
    context: Optional[str] = None
    chat_history: Optional[List[dict]] = None

class VisitRecordCreate(BaseModel):
    date: str
    doctor_notes: Optional[str] = None
    prescription: Optional[str] = None
    hb: Optional[float] = None
    ferritin: Optional[float] = None
    weight: Optional[float] = None
    bp: Optional[str] = None

class VisitRecordResponse(VisitRecordCreate):
    id: int
    patient_user_id: int
    doctor_id: int

    class Config:
        from_attributes = True

class MedicalReportResponse(BaseModel):
    id: int
    patient_user_id: Optional[int] = None
    uploader_user_id: int
    date: str
    report_type: str
    file_path: str
    analysis_summary: Optional[str] = None
    is_own_report: str

    class Config:
        from_attributes = True

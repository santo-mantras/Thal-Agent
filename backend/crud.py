from sqlalchemy.orm import Session
import models
import schemas
from datetime import datetime
import json

def get_user_by_username(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first()

def get_all_users(db: Session):
    return db.query(models.User).all()

def delete_user(db: Session, user_id: int):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user:
        # Manually delete dependent records
        db.query(models.PatientRecord).filter(models.PatientRecord.user_id == user_id).delete()
        db.query(models.DoctorProfile).filter(models.DoctorProfile.user_id == user_id).delete()
        db.query(models.ChatSession).filter(models.ChatSession.user_id == user_id).delete()
        db.query(models.VisitRecord).filter((models.VisitRecord.patient_user_id == user_id) | (models.VisitRecord.doctor_id == user_id)).delete()
        db.query(models.MedicalReport).filter((models.MedicalReport.patient_user_id == user_id) | (models.MedicalReport.uploader_user_id == user_id)).delete()
        
        db.delete(user)
        db.commit()
        return True
    return False

def update_user_profile(db: Session, user_id: int, updates: dict):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return None
        
    if user.role == "patient":
        record = db.query(models.PatientRecord).filter(models.PatientRecord.user_id == user_id).first()
        if record:
            for k, v in updates.items():
                if hasattr(record, k):
                    setattr(record, k, v)
    elif user.role == "doctor":
        profile = db.query(models.DoctorProfile).filter(models.DoctorProfile.user_id == user_id).first()
        if profile:
            for k, v in updates.items():
                if hasattr(profile, k):
                    setattr(profile, k, v)
    
    db.commit()
    return True

def create_user(db: Session, user: schemas.UserCreate):
    db_user = models.User(username=user.username, role=user.role)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def create_patient_record(db: Session, record: schemas.PatientRecordCreate, user_id: int):
    db_record = models.PatientRecord(**record.dict(), user_id=user_id)
    db.add(db_record)
    db.commit()
    db.refresh(db_record)
    return db_record

def get_patient_record(db: Session, user_id: int):
    return db.query(models.PatientRecord).filter(models.PatientRecord.user_id == user_id).first()

def update_patient_record(db: Session, user_id: int, updates: dict):
    db_record = db.query(models.PatientRecord).filter(models.PatientRecord.user_id == user_id).first()
    if db_record:
        for key, value in updates.items():
            setattr(db_record, key, value)
            
        # Auto-calculate BMI
        if db_record.height and db_record.weight and db_record.height > 0:
            height_m = db_record.height / 100.0
            db_record.bmi = round(db_record.weight / (height_m * height_m), 2)
            
        db.commit()
        db.refresh(db_record)
    return db_record

def create_doctor_profile(db: Session, profile: schemas.DoctorProfileCreate, user_id: int):
    db_profile = models.DoctorProfile(**profile.dict(), user_id=user_id)
    db.add(db_profile)
    db.commit()
    db.refresh(db_profile)
    return db_profile

def get_doctor_profile(db: Session, user_id: int):
    return db.query(models.DoctorProfile).filter(models.DoctorProfile.user_id == user_id).first()

def create_chat_session(db: Session, user_id: int, messages: str):
    # Enforce limit of 6
    sessions = db.query(models.ChatSession).filter(models.ChatSession.user_id == user_id).order_by(models.ChatSession.id).all()
    if len(sessions) >= 6:
        db.delete(sessions[0]) # delete oldest
        
    db_session = models.ChatSession(
        user_id=user_id, 
        messages=messages, 
        created_at=datetime.utcnow().isoformat()
    )
    db.add(db_session)
    db.commit()
    db.refresh(db_session)
    return db_session

def get_chat_sessions(db: Session, user_id: int):
    return db.query(models.ChatSession).filter(models.ChatSession.user_id == user_id).all()

def create_visit_record(db: Session, record: schemas.VisitRecordCreate, patient_id: int, doctor_id: int):
    db_record = models.VisitRecord(**record.dict(), patient_user_id=patient_id, doctor_id=doctor_id)
    db.add(db_record)
    
    # Also update the latest vitals in PatientRecord
    patient = db.query(models.PatientRecord).filter(models.PatientRecord.user_id == patient_id).first()
    if patient:
        if record.hb is not None:
            patient.latest_hb = record.hb
            patient.date_hb_test = record.date
        if record.ferritin is not None:
            patient.latest_ferritin = record.ferritin
            patient.date_ferritin_test = record.date
        if record.bp is not None:
            patient.bp = record.bp
        if record.weight is not None:
            patient.weight = record.weight
            if patient.height and patient.height > 0:
                patient.bmi = round(patient.weight / ((patient.height / 100) ** 2), 2)
                
    db.commit()
    db.refresh(db_record)
    return db_record

def get_visit_records(db: Session, patient_id: int, limit: int = 30):
    return db.query(models.VisitRecord).filter(models.VisitRecord.patient_user_id == patient_id).order_by(models.VisitRecord.date.desc()).limit(limit).all()

def create_medical_report(db: Session, report_data: dict):
    db_report = models.MedicalReport(**report_data)
    db.add(db_report)
    db.commit()
    db.refresh(db_report)
    return db_report

def get_medical_reports(db: Session, patient_id: int):
    return db.query(models.MedicalReport).filter(models.MedicalReport.patient_user_id == patient_id).all()

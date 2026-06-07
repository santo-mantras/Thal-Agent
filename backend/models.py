from sqlalchemy import Boolean, Column, Integer, String, Float, ForeignKey, Text
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    role = Column(String) # "patient", "doctor", "general"

    patient_record = relationship("PatientRecord", foreign_keys="[PatientRecord.user_id]", back_populates="user", uselist=False)
    doctor_profile = relationship("DoctorProfile", back_populates="user", uselist=False)
    chat_sessions = relationship("ChatSession", back_populates="user")

class PatientRecord(Base):
    __tablename__ = "patient_records"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    doctor_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    # Basic Info
    name = Column(String)
    age = Column(Integer)
    sex = Column(String)
    is_married = Column(Boolean, default=False)
    has_children = Column(Boolean, default=False)
    partner_thalassemic = Column(String, default="No")

    # Clinical History
    thalassemia_type = Column(String, nullable=True)
    blood_transfusion_volume = Column(String, nullable=True)
    blood_transfusion_frequency = Column(String, nullable=True)
    last_transfusion_date = Column(String, nullable=True)
    next_transfusion_date = Column(String, nullable=True)
    spleen_removed = Column(Boolean, default=False)
    spleen_removed_date = Column(String, nullable=True)

    # Test Results
    latest_hb = Column(Float, nullable=True)
    date_hb_test = Column(String, nullable=True)
    latest_ferritin = Column(Float, nullable=True)
    date_ferritin_test = Column(String, nullable=True)
    latest_t2_mri = Column(Float, nullable=True)
    date_t2_mri = Column(String, nullable=True)
    height = Column(Float, nullable=True)
    weight = Column(Float, nullable=True)
    bp = Column(String, nullable=True)
    sugar = Column(Float, nullable=True)
    bmi = Column(Float, nullable=True)
    platelets = Column(Float, nullable=True)
    other_tests = Column(String, nullable=True)

    # Logistics & Costs
    city = Column(String, nullable=True)
    state = Column(String, nullable=True)
    hospital_city = Column(String, nullable=True)
    hospital_state = Column(String, nullable=True)
    hospital_type = Column(String, nullable=True)
    transfusion_cost = Column(String, nullable=True)
    medicine_cost = Column(String, nullable=True)
    other_costs = Column(String, nullable=True)

    # Medicines
    medicines = Column(Text, nullable=True) # JSON list or string
    medicine_adherence = Column(String, nullable=True)

    # Doctor Fields
    doctor_notes = Column(Text, nullable=True)
    prescription = Column(Text, nullable=True)

    user = relationship("User", foreign_keys=[user_id], back_populates="patient_record")

class DoctorProfile(Base):
    __tablename__ = "doctor_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))

    name = Column(String)
    age = Column(Integer)
    sex = Column(String)
    specialty = Column(String)
    experience_years = Column(Integer)
    patient_load = Column(String)
    hospital_name = Column(String)
    city = Column(String)
    state = Column(String)

    user = relationship("User", back_populates="doctor_profile")

class ChatSession(Base):
    __tablename__ = "chat_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    messages = Column(Text) # JSON serialized list of messages
    created_at = Column(String)

    user = relationship("User", back_populates="chat_sessions")

class VisitRecord(Base):
    __tablename__ = "visit_records"

    id = Column(Integer, primary_key=True, index=True)
    patient_user_id = Column(Integer, ForeignKey("users.id"))
    doctor_id = Column(Integer, ForeignKey("users.id"))
    date = Column(String)
    
    doctor_notes = Column(Text, nullable=True)
    prescription = Column(Text, nullable=True)
    
    hb = Column(Float, nullable=True)
    ferritin = Column(Float, nullable=True)
    weight = Column(Float, nullable=True)
    bp = Column(String, nullable=True)

    patient = relationship("User", foreign_keys=[patient_user_id])
    doctor = relationship("User", foreign_keys=[doctor_id])

class MedicalReport(Base):
    __tablename__ = "medical_reports"

    id = Column(Integer, primary_key=True, index=True)
    patient_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    uploader_user_id = Column(Integer, ForeignKey("users.id"))
    date = Column(String)
    report_type = Column(String)
    file_path = Column(String)
    analysis_summary = Column(Text, nullable=True)
    is_own_report = Column(String, default="Own Report")

    patient = relationship("User", foreign_keys=[patient_user_id])
    uploader = relationship("User", foreign_keys=[uploader_user_id])

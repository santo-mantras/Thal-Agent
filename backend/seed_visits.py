import sqlite3
import datetime
import random

db_path = r"d:\AI_AGENTS\Thal_Agent\backend\thal_app.db"
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Get users
cursor.execute("SELECT id, username FROM users WHERE username IN ('sam', 'hari', 'tom', 'paresh maheshwari', 'paresh')")
users = cursor.fetchall()

user_map = {u[1]: u[0] for u in users}

if 'tom' not in user_map:
    print("Doctor tom not found")
    exit()

doctor_id = user_map['tom']

def seed_patient(patient_username):
    if patient_username not in user_map:
        print(f"Patient {patient_username} not found")
        return
        
    patient_id = user_map[patient_username]
    
    # Generate dates from Jan 2025 to May 2026 (~1.5 years, maybe 15 visits per patient)
    start_date = datetime.date(2025, 1, 15)
    
    # Realistic data for Indian Thal patients
    base_hb = 8.5
    base_ferritin = 1500
    base_weight = 65 if patient_username == 'sam' else 55
    
    # Delete existing visit records to avoid duplicates if run multiple times
    cursor.execute("DELETE FROM visit_records WHERE patient_user_id = ?", (patient_id,))
    
    for i in range(16):
        visit_date = start_date + datetime.timedelta(days=i*30 + random.randint(-5, 5))
        if visit_date > datetime.date(2026, 6, 1):
            break
            
        hb = round(random.uniform(6.5, 9.5), 1)
        ferritin = round(random.uniform(800, 2500), 1)
        weight = round(base_weight + random.uniform(-2, 2), 1)
        
        bp_systolic = random.randint(110, 130)
        bp_diastolic = random.randint(70, 85)
        bp = f"{bp_systolic}/{bp_diastolic}"
        
        notes_choices = [
            "Patient looks fatigued. Complains of mild body ache. Advised regular chelation.",
            "Hb dropped slightly. Scheduling PRBC transfusion next week. Continue Deferasirox.",
            "Ferritin levels are rising. Discussed adherence to iron chelation therapy.",
            "Patient is stable. No new complaints. Spleen size normal on palpation.",
            "Mild jaundice observed. Liver function test advised. Continue current diet.",
            "Post-transfusion checkup. Hb improved to safe levels. Advised calcium supplements.",
            "Patient reports good energy levels. Chelation compliance is adequate.",
            "Heart palpitations reported. Scheduled T2* MRI for cardiac iron overload check."
        ]
        
        prescriptions = [
            "Deferasirox 400mg OD, Folic Acid 5mg OD",
            "Deferasirox 500mg OD, Calcium D3",
            "Deferiprone 500mg TDS, Folic Acid 5mg OD",
            "Asunra 400mg OD, Vitamin C 500mg OD",
            "Kelfer 500mg TDS, Folic Acid"
        ]
        
        note = random.choice(notes_choices)
        rx = random.choice(prescriptions)
        
        date_str = visit_date.isoformat() + "T00:00:00.000Z"
        
        cursor.execute('''
            INSERT INTO visit_records (patient_user_id, doctor_id, date, doctor_notes, prescription, hb, ferritin, weight, bp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (patient_id, doctor_id, date_str, note, rx, hb, ferritin, weight, bp))
        
        # Update patient_records with the latest data from the last visit
        if i == 15 or visit_date >= datetime.date(2026, 5, 1):
            cursor.execute('''
                UPDATE patient_records 
                SET latest_hb = ?, date_hb_test = ?, latest_ferritin = ?, date_ferritin_test = ?, weight = ?, bp = ?
                WHERE user_id = ?
            ''', (hb, date_str, ferritin, date_str, weight, bp, patient_id))

seed_patient('sam')
seed_patient('hari')
seed_patient('paresh')
seed_patient('paresh maheshwari')

conn.commit()
print("Data seeded successfully")
conn.close()

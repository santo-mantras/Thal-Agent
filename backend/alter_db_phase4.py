import sqlite3
import os

db_path = r"d:\AI_AGENTS\Thal_Agent\backend\thal_app.db"

if os.path.exists(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    try:
        cursor.execute("ALTER TABLE patient_records ADD COLUMN height REAL;")
        print("Added height column.")
    except Exception as e:
        print(f"height: {e}")
    try:
        cursor.execute("ALTER TABLE patient_records ADD COLUMN doctor_id INTEGER;")
        print("Added doctor_id column.")
    except Exception as e:
        print(f"doctor_id: {e}")
    
    conn.commit()
    conn.close()
    print("Done")
else:
    print("DB not found")

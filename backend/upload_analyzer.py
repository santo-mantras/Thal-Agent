import os
import json
import requests
import fitz
from rapidocr_onnxruntime import RapidOCR

def extract_text_from_bytes(file_bytes: bytes, filename: str) -> str:
    ext = filename.lower().split('.')[-1]
    if ext == 'pdf':
        try:
            doc = fitz.open(stream=file_bytes, filetype="pdf")
            text = ""
            for page in doc:
                text += page.get_text() + "\n"
            return text
        except Exception as e:
            return f"Error extracting PDF: {e}"
    elif ext in ['png', 'jpg', 'jpeg']:
        try:
            ocr = RapidOCR()
            result, _ = ocr(file_bytes)
            text = ""
            if result:
                for line in result:
                    text += line[1] + "\n"
            return text
        except Exception as e:
            return f"Error extracting Image: {e}"
    else:
        # maybe text file or csv
        try:
            return file_bytes.decode('utf-8')
        except:
            return "Unsupported file type."

def verify_and_anonymize(text: str, user_name: str) -> tuple:
    # Very basic anonymization for prototype
    # Check if any part of the name is in the text
    name_parts = [p.lower() for p in user_name.split() if len(p) > 2]
    
    verified = False
    text_lower = text.lower()
    for part in name_parts:
        if part in text_lower:
            verified = True
            break
            
    # Redact lines with the name
    lines = text.split('\n')
    anonymized_lines = []
    for line in lines:
        line_lower = line.lower()
        if any(part in line_lower for part in name_parts) and name_parts:
            anonymized_lines.append("[REDACTED_NAME_LINE]")
        else:
            anonymized_lines.append(line)
            
    return verified, "\n".join(anonymized_lines)

def analyze_report_with_gemini(anonymized_text: str, report_type: str, is_own_report: str) -> dict:
    gemini_api_key = os.getenv("GEMINI_API_KEY")
    if not gemini_api_key:
        return {"error": "GEMINI_API_KEY not found"}
        
    prompt = f"""
    You are a medical AI assistant. Analyze the following anonymized medical report text.
    The user specified the report type as: "{report_type}".
    The user specified ownership as: "{is_own_report}".
    
    Based on the raw text, please:
    1. Confirm the actual report type (e.g. CBC, Ferritin, Complete Blood Count, Liver Function Test).
    2. Provide a brief 1-2 sentence summary of what this report is about.
    3. Provide key observations, abnormalities, and insights from the report (as doctor notes).
    4. Extract the following biomarkers if present:
       - Date of test (YYYY-MM-DD format if possible)
       - Hemoglobin (Hb) value in g/dL
       - Ferritin value in ng/mL
       - Weight in kg
       - Platelets in 10^9/L
       - Blood Pressure (BP)
       
    Report Text:
    {anonymized_text}
    
    Return EXACTLY a JSON object with the following schema:
    {{
      "verified_type": "string",
      "summary": "string",
      "doctor_notes": "string",
      "date": "string or null",
      "hb": float or null,
      "ferritin": float or null,
      "weight": float or null,
      "platelets": float or null,
      "bp": "string or null"
    }}
    Do not include any markdown formatting like ```json.
    """
    
    gen_url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key={gemini_api_key}"
    resp = requests.post(gen_url, json={
        "contents": [{"parts": [{"text": prompt}]}]
    })
    
    if resp.status_code != 200:
        return {"error": f"API Error: {resp.text}"}
        
    try:
        answer = resp.json()["candidates"][0]["content"]["parts"][0]["text"]
        answer = answer.strip().replace('```json', '').replace('```', '').strip()
        data = json.loads(answer)
        return data
    except Exception as e:
        return {"error": f"Failed to parse JSON from AI: {e}"}

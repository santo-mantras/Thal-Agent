import os
import requests
from dotenv import load_dotenv

load_dotenv("../.env")
api_key = os.getenv("GEMINI_API_KEY")

prompt = "Hello"
gen_url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent?key={api_key}"
gen_resp = requests.post(gen_url, json={
    "contents": [{"parts": [{"text": prompt}]}]
})

print(gen_resp.status_code)
print(gen_resp.json())

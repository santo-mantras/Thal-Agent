import os
import requests

api_key = os.getenv("GEMINI_API_KEY")

if api_key:
    url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
    resp = requests.get(url)
    if resp.status_code == 200:
        models = resp.json().get("models", [])
        for m in models:
            print(m["name"])
    else:
        print("Error:", resp.status_code, resp.text)
else:
    print("API Key not found")

import os
from dotenv import load_dotenv
load_dotenv()
key = os.getenv("GROQ_API_KEY")
print(f"Key loaded: {bool(key)}")
if key:
    print(f"First 10 chars: {key[:10]}...")
    print(f"Length: {len(key)}")
else:
    print("ERROR: No key found in environment")

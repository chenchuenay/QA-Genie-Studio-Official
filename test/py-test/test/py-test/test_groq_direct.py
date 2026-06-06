import os
from openai import OpenAI
from dotenv import load_dotenv
load_dotenv()

api_key = os.getenv("GROQ_API_KEY")
if not api_key:
    print("❌ No API key found. Check .env file.")
    exit(1)

print(f"✅ API key loaded (first 5 chars): {api_key[:5]}...")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.groq.com/openai/v1"
)

try:
    response = client.chat.completions.create(
        model="llama-3.1-8b-instant",
        messages=[{"role": "user", "content": "Say 'API works'"}],
        max_tokens=10
    )
    print("✅ SUCCESS! Response:", response.choices[0].message.content)
except Exception as e:
    print(f"❌ FAILED: {e}")

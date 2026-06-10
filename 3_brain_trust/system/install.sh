#!/bin/bash

echo "🚀 [1/5] กำลังเตรียมพื้นที่และสร้างไฟล์สำหรับ AI HR Agent..."

# 1. สร้างโครงสร้างโฟลเดอร์ให้ครบ
mkdir -p hr_ai_agent/data
mkdir -p hr_ai_agent/output
mkdir -p hr_ai_agent/input
cd hr_ai_agent

# 2. สร้างไฟล์ docker-compose.yml (เพิ่ม Jupyter Notebook และ Streamlit)
cat << 'EOF' > docker-compose.yml
version: '3.8'

services:
  qdrant:
    image: qdrant/qdrant:latest
    container_name: qdrant_db
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage
    restart: always

  api:
    build: .
    container_name: hr_fastapi
    ports:
      - "8000:8000"
    volumes:
      - .:/app
    depends_on:
      - qdrant
    environment:
      - QDRANT_HOST=qdrant
      - QDRANT_PORT=6333
    restart: always

  jupyter:
    image: jupyter/scipy-notebook:latest
    container_name: hr_jupyter
    ports:
      - "8888:8888"
    volumes:
      - .:/home/jovyan/work
    environment:
      - JUPYTER_TOKEN=admin
    depends_on:
      - api
    restart: always

  streamlit:
    build: .
    container_name: hr_streamlit
    ports:
      - "8501:8501"
    volumes:
      - .:/app
    depends_on:
      - api
    command: ["streamlit", "run", "ui.py", "--server.port=8501", "--server.address=0.0.0.0"]
    restart: always

volumes:
  qdrant_data:
EOF

# 3. สร้างไฟล์ Dockerfile
cat << 'EOF' > Dockerfile
FROM python:3.12-slim
WORKDIR /app
RUN apt-get update && apt-get install -y build-essential libmupdf-dev && rm -rf /var/lib/apt/lists/*
COPY ./requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 8000 8501
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
EOF

# 4. สร้างไฟล์ requirements.txt (เพิ่ม streamlit และ requests)
cat << 'EOF' > requirements.txt
fastapi
uvicorn
python-multipart
dspy-ai
litellm
PyMuPDF
httpx
openai
pydantic
pandas
numpy
qdrant-client
llama-index-embeddings-openai-like
pyarrow
streamlit
requests
EOF

# 5. สร้างไฟล์ main.py (FastAPI Code + อัปเดต Qdrant query_points)
cat << 'EOF' > main.py
import os, re, json, base64, uuid
import pandas as pd
import numpy as np
import httpx, fitz
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from pydantic import BaseModel, Field
from typing import List
import dspy
from openai import OpenAI
from qdrant_client import QdrantClient
from qdrant_client.models import VectorParams, Distance, PointStruct
from llama_index.embeddings.openai_like import OpenAILikeEmbedding
import litellm

litellm.ssl_verify = False

LLM_URL = 'https://llm.services.storemesh.com/v1'
API_KEY = 'sk-mtZ_gxsMzSoUndRivO6tew'
DSPY_MODEL_NAME = 'gpt-oss:20b'
OCR_MODEL_NAME = 'typhoon-ocr1.5-3b'

QDRANT_HOST = os.getenv("QDRANT_HOST", "localhost")
QDRANT_PORT = int(os.getenv("QDRANT_PORT", 6333))
COLLECTION_NAME = "hr_skills"

app = FastAPI(title="AI HR Agent API")
custom_http_client = httpx.Client(verify=False)

lm = dspy.LM(model=f'openai/{DSPY_MODEL_NAME}', api_base=LLM_URL, api_key=API_KEY, cache=False)
dspy.configure(lm=lm)

embedding_model = OpenAILikeEmbedding(model_name="bge-m3:latest", api_base=LLM_URL, api_key=API_KEY, http_client=custom_http_client)
qdrant = QdrantClient(host=QDRANT_HOST, port=QDRANT_PORT)

@app.on_event("startup")
def startup_event():
    collections = qdrant.get_collections().collections
    if not any(c.name == COLLECTION_NAME for c in collections):
        qdrant.create_collection(collection_name=COLLECTION_NAME, vectors_config=VectorParams(size=1024, distance=Distance.COSINE))
        
    record_count = qdrant.count(collection_name=COLLECTION_NAME).count
    if record_count == 0:
        parquet_path = "/app/output/corpus.parquet"
        csv_path = "/app/data/match_job_course_v4 - skill_taxonomy.csv"
        
        if os.path.exists(parquet_path):
            print(f"📦 เจอไฟล์ {parquet_path}! กำลังยัด Vector เข้า Qdrant โดยไม่เรียก API ใหม่...")
            df = pd.read_parquet(parquet_path)
            if isinstance(df['embedding'].iloc[0], str):
                df['embedding'] = df['embedding'].apply(json.loads)
            elif isinstance(df['embedding'].iloc[0], np.ndarray):
                df['embedding'] = df['embedding'].apply(lambda x: x.tolist())
                
            points = [PointStruct(id=i, vector=row['embedding'], payload={"skill_name": row['skill_name']}) for i, row in df.iterrows()]
            qdrant.upsert(collection_name=COLLECTION_NAME, points=points)
            print("✅ ยัด Parquet สำเร็จ!")
            
        elif os.path.exists(csv_path):
            print("⚠️ ไม่เจอไฟล์ Parquet กำลังคำนวณ Embedding ใหม่จาก CSV...")
            df = pd.read_csv(csv_path).dropna(subset=['job_classification', 'skill_name'])
            unique_skills = df['skill_name'].unique()
            points = []
            embeddings_for_parquet = []
            
            for i, skill in enumerate(unique_skills):
                emb = embedding_model.get_text_embedding(str(skill))
                points.append(PointStruct(id=i, vector=emb, payload={"skill_name": skill}))
                embeddings_for_parquet.append(json.dumps(emb))
                
            qdrant.upsert(collection_name=COLLECTION_NAME, points=points)
            pd.DataFrame({'skill_name': unique_skills, 'embedding': embeddings_for_parquet}).to_parquet(parquet_path)
            print("✅ คำนวณใหม่และเซฟ Parquet สำเร็จ!")
        else:
            print("❌ ไม่พบทั้งไฟล์ Parquet และ CSV")

class ExactProfileSchema(BaseModel):
    full_name: str
    skill: List[str] = Field(description="Break down grouped skills into single individual items.")

class ResumeParsingSignature(dspy.Signature):
    resume_raw_text: str = dspy.InputField()
    parsed_profile: ExactProfileSchema = dspy.OutputField()

def smart_pdf_extractor(pdf_path: str) -> str:
    full_text = ""
    doc = fitz.open(pdf_path)
    for page_num in range(doc.page_count):
        text = doc.load_page(page_num).get_text("text")
        full_text += text + "\n\n"
    doc.close()
    return full_text

def extract_resume_logic(pdf_path: str) -> dict:
    raw_text = smart_pdf_extractor(pdf_path)
    result = dspy.ChainOfThought(ResumeParsingSignature)(resume_raw_text=raw_text)
    profile = result.parsed_profile.model_dump()
    return profile

def match_job_logic(candidate_skills: List[str]) -> dict:
    csv_path = "/app/data/match_job_course_v4 - skill_taxonomy.csv"
    if not os.path.exists(csv_path): raise FileNotFoundError("Master CSV not found in /app/data")
    raw_df = pd.read_csv(csv_path)
    matched_master_skills = set()
    for c_skill in candidate_skills:
        # อัปเดตมาใช้ query_points แทน search
        res = qdrant.query_points(collection_name=COLLECTION_NAME, query=embedding_model.get_text_embedding(c_skill), limit=1).points
        if res and res[0].score >= 0.75: matched_master_skills.add(res[0].payload["skill_name"])

    job_scores = []
    for job in raw_df['job_classification'].unique():
        req_skills = set(raw_df[raw_df['job_classification'] == job]['skill_name'])
        if not req_skills: continue
        skills_met = matched_master_skills.intersection(req_skills)
        job_scores.append({
            'job_name': job, 'skills_met_count': len(skills_met), 'match_score': (len(skills_met) / len(req_skills)) * 100,
            'matched_skills': list(skills_met), 'missing_skills': list(req_skills - skills_met)[:5]
        })
    return {"top_jobs": sorted(job_scores, key=lambda x: (x['skills_met_count'], x['match_score']), reverse=True)[:3]}

@app.post("/api/v1/extract")
async def api_extract(file: UploadFile = File(...)):
    temp_path = f"/tmp/{uuid.uuid4()}_{file.filename}"
    with open(temp_path, "wb") as f: f.write(await file.read())
    try: return {"status": "success", "data": extract_resume_logic(temp_path)}
    finally: os.remove(temp_path)

class MatchRequest(BaseModel): skills: List[str]

@app.post("/api/v1/match")
async def api_match(request: MatchRequest):
    return {"status": "success", "data": match_job_logic(request.skills)}

@app.post("/api/v1/chat")
async def api_chat(file: UploadFile = File(...), prompt: str = Form(...)):
    temp_path = f"/tmp/{uuid.uuid4()}_{file.filename}"
    with open(temp_path, "wb") as f: f.write(await file.read())
    def tool_extract(p: str): return json.dumps(extract_resume_logic(temp_path), ensure_ascii=False)
    def tool_match(s: str): return json.dumps(match_job_logic(s.split(','))['top_jobs'], ensure_ascii=False)
    try:
        agent = dspy.ReAct("question -> answer", tools=[tool_extract, tool_match])
        return {"status": "success", "answer": agent(question=f"Resume path: {temp_path}. {prompt}").answer}
    finally: os.remove(temp_path)
EOF

# 6. สร้างไฟล์ ui.py (สำหรับ Streamlit Web UI)
echo "🎨 [2/5] กำลังสร้างหน้าเว็บ Streamlit..."
cat << 'EOF' > ui.py
import streamlit as st
import requests

# ยิงไปหา API Container ที่อยู่ในวง Docker Network เดียวกัน
API_URL = "http://api:8000/api/v1/chat"

st.set_page_config(page_title="AI HR Agent", page_icon="👔", layout="centered")

st.title("👔 AI HR Agent - Resume Analyzer")
st.markdown("อัปโหลดไฟล์ PDF ของเรซูเม่ และพิมพ์คำสั่งให้ AI ช่วยวิเคราะห์ได้เลยครับ!")

uploaded_file = st.file_uploader("📂 อัปโหลดไฟล์ Resume (PDF)", type=["pdf"])
prompt = st.text_area("💬 ข้อความคำสั่ง (Prompt)", value="วิเคราะห์เรซูเม่ หาตำแหน่งงานที่เหมาะสม และสรุปสิ่งที่ควรพัฒนาให้ฟังหน่อย", height=100)

if st.button("ส่งให้ AI วิเคราะห์ 🚀"):
    if uploaded_file is not None and prompt:
        with st.spinner("🧠 AI กำลังทำงาน... (อาจใช้เวลาสักครู่)"):
            files = {"file": (uploaded_file.name, uploaded_file.getvalue(), "application/pdf")}
            data = {"prompt": prompt}
            try:
                response = requests.post(API_URL, files=files, data=data)
                if response.status_code == 200:
                    result = response.json()
                    st.success("✅ วิเคราะห์สำเร็จ!")
                    st.markdown("### 📊 ผลการวิเคราะห์")
                    st.info(result.get("answer", "ไม่มีคำตอบจาก AI"))
                else:
                    st.error(f"❌ เกิดข้อผิดพลาดจาก API (Status {response.status_code})")
                    st.write(response.text)
            except Exception as e:
                st.error(f"❌ ไม่สามารถเชื่อมต่อกับ API ได้: {e}")
    else:
        st.warning("⚠️ กรุณาอัปโหลดไฟล์และกรอกข้อความคำสั่งก่อนครับ")
EOF

# 7. สร้างไฟล์ Notebook
echo "📒 [3/5] กำลังสร้าง Jupyter Notebook..."
cat << 'EOF' > test_api.ipynb
{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import requests\n",
    "import json\n",
    "\n",
    "# ใช้ชื่อ Service 'api' แทน localhost เพราะเรายิงหากันภายใน Docker Network\n",
    "BASE_URL = 'http://api:8000/api/v1'\n",
    "PDF_PATH = './input/kitichai - kitichai paichayon.pdf' # ให้แก้ชื่อไฟล์ให้ตรงกับที่อยู่ในโฟลเดอร์ input\n",
    "\n",
    "# 1. Test Extract API\n",
    "print('--- Testing /extract ---')\n",
    "with open(PDF_PATH, 'rb') as f:\n",
    "    res_extract = requests.post(f'{BASE_URL}/extract', files={'file': f})\n",
    "print(json.dumps(res_extract.json(), indent=2, ensure_ascii=False))\n",
    "\n",
    "# 2. Test Match API\n",
    "print('\\n--- Testing /match ---')\n",
    "skills = res_extract.json().get('data', {}).get('skill', ['Python', 'Docker', 'MySQL'])\n",
    "res_match = requests.post(f'{BASE_URL}/match', json={'skills': skills})\n",
    "if res_match.status_code == 200:\n",
    "    print(json.dumps(res_match.json(), indent=2, ensure_ascii=False))\n",
    "else:\n",
    "    print(f'❌ API Error (Status {res_match.status_code}):', res_match.text)\n",
    "\n",
    "# 3. Test Chat Agent API\n",
    "print('\\n--- Testing /chat ---')\n",
    "with open(PDF_PATH, 'rb') as f:\n",
    "    res_chat = requests.post(\n",
    "        f'{BASE_URL}/chat', \n",
    "        files={'file': f}, \n",
    "        data={'prompt': 'วิเคราะห์เรซูเม่ หาตำแหน่งงานที่เหมาะสม และสรุปสิ่งที่ควรพัฒนาให้ฟังหน่อย'}\n",
    "    )\n",
    "print(res_chat.json().get('answer', 'Error'))"
   ]
  }
 ],
 "metadata": {
  "language_info": {
   "name": "python"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 2
}
EOF

if ! command -v docker-compose &> /dev/null; then
    echo "❌ ไม่พบคำสั่ง docker-compose กรุณาติดตั้งก่อนรัน"
    exit 1
fi

echo "🐳 [4/5] กำลัง Build และรัน Docker Containers..."
docker-compose up -d --build

echo "🎉 [5/5] ระบบพร้อมใช้งานแล้วครับ!"
echo "----------------------------------------------------"
echo "📌 สิ่งที่คุณต้องทำ (ลำดับการวางไฟล์):"
echo "  1. เอาไฟล์ CSV ไปใส่ที่ : hr_ai_agent/data/"
echo "  2. เอาไฟล์ corpus.parquet ไปใส่ที่ : hr_ai_agent/output/"
echo "  3. เอาไฟล์ PDF เรซูเม่ ไปใส่ที่ : hr_ai_agent/input/"
echo "  **หมายเหตุ: ถ้าย้ายไฟล์เข้าไปหลังรัน Script นี้ ให้พิมพ์คำสั่ง: cd hr_ai_agent && docker-compose restart api"
echo ""
echo "🌐 ช่องทางการเข้าถึงระบบของคุณ:"
echo "  - 🎨 Streamlit Web UI : http://localhost:8501 (แชทใช้งานง่ายๆ ผ่านหน้าเว็บ)"
echo "  - 📒 Jupyter Notebook : http://localhost:8888 (รหัสผ่าน: admin)"
echo "  - 🚀 FastAPI Docs     : http://localhost:8000/docs"
echo "----------------------------------------------------"
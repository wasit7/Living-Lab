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
        csv_path = "./data/match_job_course_v4 - skill_taxonomy.csv"
        if os.path.exists(csv_path):
            df = pd.read_csv(csv_path).dropna(subset=['job_classification', 'skill_name'])
            points = [PointStruct(id=i, vector=embedding_model.get_text_embedding(str(skill)), payload={"skill_name": skill}) for i, skill in enumerate(df['skill_name'].unique())]
            qdrant.upsert(collection_name=COLLECTION_NAME, points=points)

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
        full_text += text + "\n\n" # ย่อโค้ดเพื่อความกระชับใน API
    doc.close()
    return full_text

def extract_resume_logic(pdf_path: str) -> dict:
    raw_text = smart_pdf_extractor(pdf_path)
    result = dspy.ChainOfThought(ResumeParsingSignature)(resume_raw_text=raw_text)
    profile = result.parsed_profile.model_dump()
    return profile

def match_job_logic(candidate_skills: List[str]) -> dict:
    csv_path = "./data/match_job_course_v4 - skill_taxonomy.csv"
    if not os.path.exists(csv_path): raise FileNotFoundError("Master CSV not found in /data")
    raw_df = pd.read_csv(csv_path)
    matched_master_skills = set()
    for c_skill in candidate_skills:
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

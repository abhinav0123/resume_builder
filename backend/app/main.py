from __future__ import annotations

import re
import sqlite3
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import fitz  # PyMuPDF
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

DB_PATH = Path(__file__).resolve().parent.parent / "career_ai.db"
MAX_FILE_SIZE = 5 * 1024 * 1024
ALLOWED_CONTENT_TYPES = {"application/pdf", "application/octet-stream"}

SKILLS = {
    "flutter", "dart", "firebase", "rest api", "bloc", "cubit", "provider",
    "riverpod", "git", "android", "ios", "kotlin", "swift", "java",
    "python", "fastapi", "django", "node.js", "javascript", "typescript",
    "react", "sql", "postgresql", "mysql", "mongodb", "aws", "docker",
    "ci/cd", "unit testing", "widget testing", "integration testing",
    "graphql", "dio", "clean architecture", "mvvm", "agile"
}

JOBS = [
    {
        "id": "JOB-FL-001",
        "title": "Flutter Developer",
        "company": "MobileCraft",
        "location": "Remote / India",
        "experience_min": 2,
        "skills": ["flutter", "dart", "bloc", "rest api", "firebase", "git"],
        "description": "Build and maintain cross-platform mobile applications."
    },
    {
        "id": "JOB-MOB-002",
        "title": "Mobile Application Developer",
        "company": "AppWorks",
        "location": "Pune, India",
        "experience_min": 2,
        "skills": ["flutter", "dart", "android", "ios", "rest api", "git"],
        "description": "Develop mobile features and integrate backend services."
    },
    {
        "id": "JOB-AND-003",
        "title": "Android Developer",
        "company": "DroidLabs",
        "location": "Mumbai, India",
        "experience_min": 3,
        "skills": ["kotlin", "java", "android", "rest api", "git"],
        "description": "Develop native Android applications."
    },
    {
        "id": "JOB-PY-004",
        "title": "Python Backend Developer",
        "company": "CloudStack",
        "location": "Remote / India",
        "experience_min": 2,
        "skills": ["python", "fastapi", "postgresql", "docker", "rest api"],
        "description": "Design backend APIs and data services."
    },
]

app = FastAPI(title="CareerAI Resume Analyzer API", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict this to your app/web domains in production.
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def db() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    with db() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS resumes (
                id TEXT PRIMARY KEY,
                filename TEXT NOT NULL,
                extracted_text TEXT NOT NULL,
                analysis_json TEXT NOT NULL,
                created_at TEXT NOT NULL
            )
        """)


@app.on_event("startup")
def startup() -> None:
    init_db()


class JobResult(BaseModel):
    id: str
    title: str
    company: str
    location: str
    experience_min: int
    skills: list[str]
    description: str
    match_score: int
    matched_skills: list[str]
    missing_skills: list[str]


def extract_pdf_text(data: bytes) -> str:
    try:
        doc = fitz.open(stream=data, filetype="pdf")
        text = "\n".join(page.get_text("text") for page in doc)
        doc.close()
        return text.strip()
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Could not read PDF: {exc}")


def extract_skills(text: str) -> list[str]:
    normalized = re.sub(r"\s+", " ", text.lower())
    found = []
    for skill in sorted(SKILLS):
        # Word boundaries avoid matching 'java' inside 'javascript'.
        pattern = r"(?<![a-z0-9+#.])" + re.escape(skill) + r"(?![a-z0-9+#.])"
        if re.search(pattern, normalized):
            found.append(skill)
    return found


def extract_experience(text: str) -> float | None:
    patterns = [
        r"(\d+(?:\.\d+)?)\s*\+?\s*years?\s+(?:of\s+)?experience",
        r"experience\s*[:\-]?\s*(\d+(?:\.\d+)?)\s*\+?\s*years?"
    ]
    for pattern in patterns:
        match = re.search(pattern, text.lower())
        if match:
            return float(match.group(1))
    return None


def analyze_resume(text: str) -> dict[str, Any]:
    skills = extract_skills(text)
    experience = extract_experience(text)
    words = len(re.findall(r"\b\w+\b", text))
    return {
        "skills": skills,
        "experience_years": experience,
        "word_count": words,
        "summary": (
            f"Detected {len(skills)} skills in your resume."
            if skills else "No known skills were detected. Add a clear Skills section."
        ),
        "suggestions": [
            "Use a clearly labeled Skills section with technologies you have actually used.",
            "Add measurable achievements, such as performance improvements or users supported.",
            "Mention project outcomes and your specific contribution.",
        ],
    }


def match_jobs(analysis: dict[str, Any]) -> list[dict[str, Any]]:
    user_skills = set(analysis.get("skills", []))
    experience = analysis.get("experience_years") or 0
    results = []
    for job in JOBS:
        required = set(job["skills"])
        matched = sorted(user_skills & required)
        missing = sorted(required - user_skills)
        skill_score = (len(matched) / len(required) * 85) if required else 0
        exp_score = 15 if experience >= job["experience_min"] else (
            15 * experience / job["experience_min"] if job["experience_min"] else 15
        )
        score = round(min(100, skill_score + exp_score))
        results.append({
            **job,
            "match_score": score,
            "matched_skills": matched,
            "missing_skills": missing,
        })
    return sorted(results, key=lambda item: item["match_score"], reverse=True)


@app.get("/health")
def health():
    return {"status": "ok", "service": "career-ai"}


@app.post("/api/v1/resumes/analyze")
async def upload_and_analyze(file: UploadFile = File(...)):
    filename = file.filename or "resume.pdf"
    if not filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Please upload a PDF file.")
    if file.content_type and file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(status_code=400, detail="Only PDF files are supported.")

    data = await file.read()
    if not data:
        raise HTTPException(status_code=400, detail="The uploaded file is empty.")
    if len(data) > MAX_FILE_SIZE:
        raise HTTPException(status_code=413, detail="PDF must be 5 MB or smaller.")

    text = extract_pdf_text(data)
    if len(text) < 30:
        raise HTTPException(
            status_code=422,
            detail="Not enough selectable text found. This may be a scanned PDF; OCR is not enabled in this MVP."
        )

    analysis = analyze_resume(text)
    resume_id = str(uuid.uuid4())
    created_at = datetime.now(timezone.utc).isoformat()
    import json
    with db() as conn:
        conn.execute(
            "INSERT INTO resumes (id, filename, extracted_text, analysis_json, created_at) VALUES (?, ?, ?, ?, ?)",
            (resume_id, filename, text, json.dumps(analysis), created_at),
        )

    return {
        "resume_id": resume_id,
        "filename": filename,
        "created_at": created_at,
        "analysis": analysis,
        "recommended_jobs": match_jobs(analysis),
    }


@app.get("/api/v1/resumes/{resume_id}")
def get_resume(resume_id: str):
    import json
    with db() as conn:
        row = conn.execute("SELECT * FROM resumes WHERE id = ?", (resume_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Resume not found.")
    analysis = json.loads(row["analysis_json"])
    return {
        "resume_id": row["id"],
        "filename": row["filename"],
        "created_at": row["created_at"],
        "analysis": analysis,
        "recommended_jobs": match_jobs(analysis),
    }


@app.get("/api/v1/jobs", response_model=list[JobResult])
def get_jobs():
    empty_analysis = {"skills": [], "experience_years": 0}
    return match_jobs(empty_analysis)


@app.get("/api/v1/jobs/recommended", response_model=list[JobResult])
def recommended_jobs(resume_id: str):
    import json
    with db() as conn:
        row = conn.execute("SELECT analysis_json FROM resumes WHERE id = ?", (resume_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Resume not found.")
    return match_jobs(json.loads(row["analysis_json"]))

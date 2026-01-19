# Local Development (macOS/Linux)

## Prereqs
- Python 3.11+
- Node 18+ with yarn (or npm)
- Docker (for local MongoDB) or an external MongoDB URI

## 1) Clone and env files
```bash
cd /Users/admin/Desktop/Glass
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
```
Edit the `.env` files to add real secrets if you have them.

## 2) Start MongoDB locally
If you do not have MongoDB installed, run a container:
```bash
docker run -d --name glass-mongo -p 27017:27017 mongo:7
```

## 3) Backend setup
```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
# run API (main customer API)
uvicorn server:app --reload --host 0.0.0.0 --port 8000
# optional: run ERP API separately if needed
# uvicorn erp_server:app --reload --host 0.0.0.0 --port 8001
```
Notes:
- The backend reads env from `backend/.env` (must include at least `MONGO_URL`, `DB_NAME`, `JWT_SECRET`).
- Seed data (products/pricing) runs on startup in `server.py`.

## 4) Frontend setup
```bash
cd frontend
yarn install
REACT_APP_BACKEND_URL=http://localhost:8000 yarn start
```
This starts the React dev server on port 3000. Ensure `CORS_ORIGINS` in `backend/.env` includes `http://localhost:3000`.

## 5) Quick smoke test
- Open http://localhost:3000 in a browser.
- Test API health: `curl http://localhost:8000/health`.

## 6) Stopping services
```bash
docker stop glass-mongo
# stop uvicorn with Ctrl+C
```

## Troubleshooting
- If the backend fails on startup: verify `MONGO_URL`, and that MongoDB is reachable.
- For CORS issues: set `CORS_ORIGINS=http://localhost:3000` in `backend/.env`.
- Razorpay/Twilio/SMTP are optional for local; keep placeholders unless testing those flows.

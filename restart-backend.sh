#!/bin/bash
# Quick script to restart backend after MongoDB is ready

echo "Stopping existing backend..."
pkill -f "uvicorn server:app" 2>/dev/null
lsof -ti :8000 | xargs kill -9 2>/dev/null
sleep 2

echo "Starting backend..."
cd /Users/admin/Desktop/Glass/backend
/Users/admin/Desktop/Glass/.venv/bin/python -m uvicorn server:app --reload --host 0.0.0.0 --port 8000 &

sleep 5
echo ""
echo "Checking backend status..."
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✓ Backend is running on http://localhost:8000"
else
    echo "✗ Backend failed to start"
    echo "Check logs with: tail -f ~/glass-backend.log"
fi

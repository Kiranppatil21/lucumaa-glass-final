#!/bin/bash

echo "========================================="
echo "Glass ERP - Quick Start Script"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if MongoDB is installed
if ! command -v mongod &> /dev/null; then
    echo -e "${RED}✗ MongoDB is not installed${NC}"
    echo ""
    echo "Installing MongoDB..."
    brew tap mongodb/brew 2>/dev/null
    brew install mongodb-community@7.0
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install MongoDB. Please install manually:${NC}"
        echo "brew tap mongodb/brew && brew install mongodb-community@7.0"
        exit 1
    fi
fi

echo -e "${GREEN}✓ MongoDB is installed${NC}"

# Start MongoDB
if ! pgrep -x "mongod" > /dev/null; then
    echo "Starting MongoDB..."
    mkdir -p ~/mongodb-data
    mongod --dbpath ~/mongodb-data --fork --logpath ~/mongodb-data/mongodb.log
    sleep 3
fi

if pgrep -x "mongod" > /dev/null; then
    echo -e "${GREEN}✓ MongoDB is running${NC}"
else
    echo -e "${RED}✗ Failed to start MongoDB${NC}"
    echo "Try starting manually: mongod --dbpath ~/mongodb-data"
    exit 1
fi

# Seed admin user
echo ""
echo "Seeding admin user..."
cd /Users/admin/Desktop/Glass/backend
/Users/admin/Desktop/Glass/.venv/bin/python seed_admin.py

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Admin user ready${NC}"
else
    echo -e "${YELLOW}⚠ Admin user may already exist or will be created on first backend start${NC}"
fi

# Kill existing servers
echo ""
echo "Stopping existing servers..."
pkill -f "uvicorn server:app" 2>/dev/null
lsof -ti :8000 | xargs kill -9 2>/dev/null
pkill -f "craco start" 2>/dev/null
lsof -ti :3000 | xargs kill -9 2>/dev/null
sleep 2

# Start backend
echo "Starting backend server..."
cd /Users/admin/Desktop/Glass/backend
nohup /Users/admin/Desktop/Glass/.venv/bin/python -m uvicorn server:app --reload --host 0.0.0.0 --port 8000 > ~/glass-backend.log 2>&1 &
BACKEND_PID=$!
sleep 5

# Check if backend started
if curl -s http://localhost:8000/health > /dev/null; then
    echo -e "${GREEN}✓ Backend running on http://localhost:8000${NC}"
else
    echo -e "${RED}✗ Backend failed to start. Check ~/glass-backend.log${NC}"
fi

# Start frontend
echo "Starting frontend server..."
cd /Users/admin/Desktop/Glass/frontend
nohup npm start > ~/glass-frontend.log 2>&1 &
FRONTEND_PID=$!
sleep 10

# Check if frontend started
if curl -s http://localhost:3000 > /dev/null; then
    echo -e "${GREEN}✓ Frontend running on http://localhost:3000${NC}"
else
    echo -e "${YELLOW}⚠ Frontend may still be compiling. Check ~/glass-frontend.log${NC}"
fi

echo ""
echo "========================================="
echo -e "${GREEN}Glass ERP is ready!${NC}"
echo "========================================="
echo ""
echo "Frontend: http://localhost:3000"
echo "Backend:  http://localhost:8000"
echo ""
echo "Login credentials:"
echo "  Email:    admin@lucumaa.in"
echo "  Password: adminpass"
echo ""
echo "Logs:"
echo "  Backend:  ~/glass-backend.log"
echo "  Frontend: ~/glass-frontend.log"
echo "  MongoDB:  ~/mongodb-data/mongodb.log"
echo ""
echo "To stop servers:"
echo "  pkill -f 'uvicorn server:app'"
echo "  pkill -f 'craco start'"
echo "  pkill mongod"
echo ""

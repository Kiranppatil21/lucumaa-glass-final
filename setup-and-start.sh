#!/bin/bash

echo "================================================"
echo "  Glass ERP - Final Setup & Start"
echo "================================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Verify MongoDB is installed
echo -e "${BLUE}Step 1: Checking MongoDB installation...${NC}"
if ! command -v mongod &> /dev/null; then
    echo -e "${RED}✗ MongoDB is not installed yet${NC}"
    echo "Please wait for 'brew install mongodb-community@7.0' to complete"
    echo "Then run this script again"
    exit 1
fi
echo -e "${GREEN}✓ MongoDB is installed${NC}"
echo ""

# Step 2: Create MongoDB data directory
echo -e "${BLUE}Step 2: Setting up MongoDB data directory...${NC}"
mkdir -p ~/mongodb-data
echo -e "${GREEN}✓ MongoDB data directory created${NC}"
echo ""

# Step 3: Start MongoDB
echo -e "${BLUE}Step 3: Starting MongoDB...${NC}"
if pgrep -x "mongod" > /dev/null; then
    echo -e "${YELLOW}MongoDB is already running${NC}"
else
    mongod --dbpath ~/mongodb-data --fork --logpath ~/mongodb-data/mongodb.log --bind_ip 127.0.0.1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ MongoDB started successfully${NC}"
    else
        echo -e "${RED}✗ Failed to start MongoDB${NC}"
        echo "Try running manually: mongod --dbpath ~/mongodb-data"
        exit 1
    fi
fi
echo ""

# Step 4: Wait for MongoDB to be ready
echo -e "${BLUE}Step 4: Waiting for MongoDB to be ready...${NC}"
sleep 3
echo -e "${GREEN}✓ MongoDB is ready${NC}"
echo ""

# Step 5: Seed admin user
echo -e "${BLUE}Step 5: Creating admin user...${NC}"
cd /Users/admin/Desktop/Glass/backend
/Users/admin/Desktop/Glass/.venv/bin/python seed_admin.py
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Admin user created/verified${NC}"
else
    echo -e "${YELLOW}⚠ Admin user may already exist${NC}"
fi
echo ""

# Step 6: Stop any existing servers
echo -e "${BLUE}Step 6: Stopping existing servers...${NC}"
pkill -f "uvicorn server:app" 2>/dev/null
lsof -ti :8000 | xargs kill -9 2>/dev/null
sleep 2
echo -e "${GREEN}✓ Old servers stopped${NC}"
echo ""

# Step 7: Start backend
echo -e "${BLUE}Step 7: Starting backend server...${NC}"
cd /Users/admin/Desktop/Glass/backend
nohup /Users/admin/Desktop/Glass/.venv/bin/python -m uvicorn server:app --reload --host 0.0.0.0 --port 8000 > ~/glass-backend.log 2>&1 &
BACKEND_PID=$!
echo "Backend PID: $BACKEND_PID"
sleep 8

# Verify backend
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Backend is running on http://localhost:8000${NC}"
else
    echo -e "${RED}✗ Backend failed to start${NC}"
    echo "Check logs: tail -50 ~/glass-backend.log"
    exit 1
fi
echo ""

# Step 8: Check frontend
echo -e "${BLUE}Step 8: Checking frontend...${NC}"
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Frontend is running on http://localhost:3000${NC}"
else
    echo -e "${YELLOW}⚠ Frontend is not running${NC}"
    echo "Start it with: cd /Users/admin/Desktop/Glass/frontend && npm start"
fi
echo ""

# Final summary
echo "================================================"
echo -e "${GREEN}  Glass ERP Setup Complete!${NC}"
echo "================================================"
echo ""
echo -e "${BLUE}Access the application:${NC}"
echo "  Frontend: http://localhost:3000"
echo "  Backend:  http://localhost:8000"
echo ""
echo -e "${BLUE}Login credentials:${NC}"
echo -e "  ${GREEN}Email:${NC}    admin@lucumaa.in"
echo -e "  ${GREEN}Password:${NC} adminpass"
echo -e "  ${GREEN}Role:${NC}     super_admin"
echo ""
echo -e "${BLUE}Logs:${NC}"
echo "  Backend:  ~/glass-backend.log"
echo "  MongoDB:  ~/mongodb-data/mongodb.log"
echo ""
echo -e "${BLUE}To stop services:${NC}"
echo "  pkill -f 'uvicorn server:app'  # Stop backend"
echo "  pkill -f 'craco start'          # Stop frontend"
echo "  pkill mongod                    # Stop MongoDB"
echo ""
echo "================================================"

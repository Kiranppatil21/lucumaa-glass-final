#!/bin/bash
# Build script for production deployment
# Run this locally before uploading to server

set -e

echo "======================================"
echo "Glass ERP - Building for Production"
echo "======================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${YELLOW}Step 1: Building Frontend...${NC}"
cd "$SCRIPT_DIR/frontend"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing frontend dependencies..."
    npm install --legacy-peer-deps
fi

# Build
echo "Building React app..."
npm run build

if [ -d "build" ]; then
    echo -e "${GREEN}✓ Frontend built successfully${NC}"
    echo "  Output: $SCRIPT_DIR/frontend/build/"
    echo "  Size: $(du -sh build | cut -f1)"
else
    echo -e "${RED}✗ Frontend build failed${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 2: Preparing Backend...${NC}"
cd "$SCRIPT_DIR/backend"

# Check requirements.txt exists
if [ ! -f "requirements.txt" ]; then
    echo -e "${RED}✗ requirements.txt not found${NC}"
    exit 1
fi

# Create production .env template if it doesn't exist
if [ ! -f ".env.production" ]; then
    echo "Creating .env.production template..."
    cat > .env.production << 'EOF'
# MongoDB Atlas Connection (REQUIRED)
MONGO_URL=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
DB_NAME=lucumaa

# JWT Secret (REQUIRED)
JWT_SECRET=change-this-to-random-string

# Razorpay (Optional)
RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=

# Email (Optional)
EMAIL_FROM=noreply@yourdomain.com
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=
EOF
fi

echo -e "${GREEN}✓ Backend prepared${NC}"

echo ""
echo -e "${YELLOW}Step 3: Creating deployment package...${NC}"

# Create deployment directory
DEPLOY_DIR="$SCRIPT_DIR/glass-erp-deployment"
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"

# Copy frontend build
echo "Copying frontend..."
cp -r "$SCRIPT_DIR/frontend/build" "$DEPLOY_DIR/frontend"

# Copy backend
echo "Copying backend..."
mkdir -p "$DEPLOY_DIR/backend"
cd "$SCRIPT_DIR/backend"

# Copy only necessary backend files
cp -r *.py "$DEPLOY_DIR/backend/" 2>/dev/null || true
cp requirements.txt "$DEPLOY_DIR/backend/"
cp .env.example "$DEPLOY_DIR/backend/" 2>/dev/null || true
cp .env.production "$DEPLOY_DIR/backend/"
cp -r models "$DEPLOY_DIR/backend/" 2>/dev/null || true
cp -r routers "$DEPLOY_DIR/backend/" 2>/dev/null || true
cp -r utils "$DEPLOY_DIR/backend/" 2>/dev/null || true

# Create uploads directory
mkdir -p "$DEPLOY_DIR/backend/uploads"

# Copy deployment scripts
echo "Copying deployment scripts..."
cp "$SCRIPT_DIR/deploy-to-hostinger.sh" "$DEPLOY_DIR/"
cp "$SCRIPT_DIR/HOSTINGER_DEPLOYMENT.md" "$DEPLOY_DIR/"
cp "$SCRIPT_DIR/UPLOAD_INSTRUCTIONS.md" "$DEPLOY_DIR/"

echo -e "${GREEN}✓ Deployment package created${NC}"

echo ""
echo "======================================"
echo -e "${GREEN}Build Complete!${NC}"
echo "======================================"
echo ""
echo "Deployment package location:"
echo "  $DEPLOY_DIR"
echo ""
echo "Package size: $(du -sh "$DEPLOY_DIR" | cut -f1)"
echo ""
echo "Next steps:"
echo "1. Review deployment guide: $DEPLOY_DIR/HOSTINGER_DEPLOYMENT.md"
echo "2. Set up MongoDB Atlas (free): https://www.mongodb.com/cloud/atlas"
echo "3. Configure .env.production with your settings"
echo "4. Upload to Hostinger using instructions in UPLOAD_INSTRUCTIONS.md"
echo ""
echo "Quick upload command:"
echo "  scp -r $DEPLOY_DIR/backend root@YOUR_VPS_IP:/var/www/glass-erp/"
echo "  scp -r $DEPLOY_DIR/frontend root@YOUR_VPS_IP:/var/www/glass-erp/"
echo ""

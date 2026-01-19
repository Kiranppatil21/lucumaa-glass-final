#!/bin/bash
# Fix Frontend Build Issue on VPS

echo "🔧 Fixing frontend build issue..."
cd ~/Glass/frontend

# Clean everything
echo "Cleaning npm cache and node_modules..."
rm -rf node_modules package-lock.json
npm cache clean --force

# Reinstall dependencies with proper flags
echo "Reinstalling dependencies..."
npm install --legacy-peer-deps --no-optional

# Explicitly install lodash (fixes the missing module issue)
echo "Installing lodash explicitly..."
npm install lodash --legacy-peer-deps

# Try building again
echo "Building frontend..."
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Frontend built successfully!"
else
    echo ""
    echo "❌ Build failed. Trying alternative method..."
    
    # Alternative: Install with exact versions
    npm install react@19.0.0 react-dom@19.0.0 --legacy-peer-deps
    npm run build
fi

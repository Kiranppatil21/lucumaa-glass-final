#!/bin/bash
# Clean Glass Project for VPS Upload
# This removes all unnecessary files that can be regenerated

cd /Users/admin/Desktop/Glass

echo "🧹 Cleaning Glass project for VPS upload..."
echo ""

# Remove node_modules (1.6GB - can reinstall with npm install)
echo "Removing frontend/node_modules..."
rm -rf frontend/node_modules

# Remove frontend build (9.3MB - will rebuild on VPS)
echo "Removing frontend/build..."
rm -rf frontend/build

# Remove Python virtual environment (can recreate with python -m venv)
echo "Removing Python venv..."
rm -rf venv .venv

# Remove Python cache
echo "Removing Python __pycache__..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null

# Remove .pyc files
echo "Removing .pyc files..."
find . -type f -name "*.pyc" -delete 2>/dev/null

# Remove Mac system files
echo "Removing .DS_Store files..."
find . -name ".DS_Store" -delete 2>/dev/null

# Remove log files
echo "Removing log files..."
rm -rf logs/*.log 2>/dev/null
rm -rf backend/logs/*.log 2>/dev/null

# Remove temp files
echo "Removing temp files..."
rm -rf *.log temp tmp 2>/dev/null

# Remove uploads folder (if exists and large)
echo "Removing uploads..."
rm -rf uploads/* 2>/dev/null

# Remove test reports (optional - can keep if needed)
# rm -rf test_reports 2>/dev/null

# Remove coverage reports
echo "Removing coverage files..."
rm -rf .coverage htmlcov .pytest_cache 2>/dev/null

# Remove package-lock (will regenerate)
echo "Removing package-lock.json..."
rm -f frontend/package-lock.json

# Remove deployment folders we don't need
echo "Removing glass-erp-deployment folder..."
rm -rf glass-erp-deployment

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Project size after cleanup:"
du -sh /Users/admin/Desktop/Glass
echo ""
echo "You can now zip the project:"
echo "  cd /Users/admin/Desktop"
echo "  tar -czf Glass.tar.gz Glass/"
echo ""

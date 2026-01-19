#!/bin/bash
# Fix Python 3.11 Installation on Ubuntu VPS

echo "Fixing Python 3.11 installation..."

# Add deadsnakes PPA (required for Python 3.11)
echo "Adding deadsnakes PPA..."
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa

# Update package list
echo "Updating package list..."
sudo apt update

# Install Python 3.11
echo "Installing Python 3.11..."
sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip

# Verify installation
echo ""
echo "Verification:"
python3.11 --version

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Python 3.11 installed successfully!"
    echo ""
    echo "You can now continue with the deployment."
else
    echo ""
    echo "❌ Installation failed. Please check the errors above."
fi

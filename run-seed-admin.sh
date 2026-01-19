#!/usr/bin/env bash
cd /root/glass-deploy-20260107-190639/backend
source venv/bin/activate
export MONGO_URL=mongodb://localhost:27017
export DB_NAME=glass_erp
python3 seed_admin.py

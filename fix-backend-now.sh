#!/usr/bin/env bash
cd /root/glass-deploy-20260107-190639/backend

echo "🔧 Fixing backend startup..."

# Stop all processes
pm2 delete all 2>/dev/null || true
pkill -f uvicorn || true
sleep 2

# Create .env file
cat > .env << 'EOF'
SMTP_HOST=smtp.hostinger.com
SMTP_PORT=465
SMTP_USER=info@lucumaaglass.in
SMTP_PASSWORD=Info123@@123
EOF

# Load environment and start uvicorn
source venv/bin/activate
export SMTP_HOST=smtp.hostinger.com
export SMTP_PORT=465
export SMTP_USER=info@lucumaaglass.in
export SMTP_PASSWORD="Info123@@123"

# Start backend
nohup venv/bin/python -m uvicorn server:app --host 0.0.0.0 --port 8000 > /tmp/backend.log 2>&1 &
echo $! > /tmp/backend.pid

sleep 5

# Check status
if curl -s http://localhost:8000/health > /dev/null; then
    echo "✅ Backend running on PID: $(cat /tmp/backend.pid)"
    
    # Test email
    venv/bin/python -c "
import asyncio
import aiosmtplib
from email.message import EmailMessage

async def test():
    msg = EmailMessage()
    msg['From'] = 'info@lucumaaglass.in'
    msg['To'] = 'admin@lucumaaglass.in'
    msg['Subject'] = 'VPS Fix - Test Email'
    msg.set_content('Backend restarted with SMTP configuration. This is a test email.')
    try:
        await aiosmtplib.send(msg, hostname='smtp.hostinger.com', port=465,
            username='info@lucumaaglass.in', password='Info123@@123', use_tls=True)
        print('✅ Test email sent successfully!')
    except Exception as e:
        print(f'❌ Email error: {e}')

asyncio.run(test())
"
else
    echo "❌ Backend failed to start"
    echo "Last 30 lines of log:"
    tail -30 /tmp/backend.log
fi

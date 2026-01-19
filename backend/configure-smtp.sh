#!/bin/bash
# Configure SMTP for email notifications

echo "🔧 SMTP Email Configuration for Lucumaa Glass"
echo "=============================================="
echo ""
echo "Current SMTP settings in .env:"
grep "^SMTP_" .env || echo "No SMTP settings found"
echo ""
echo "To enable emails, you need valid SMTP credentials."
echo ""
echo "For Hostinger SMTP:"
echo "  SMTP_HOST=smtp.hostinger.com"
echo "  SMTP_PORT=465"
echo "  SMTP_USER=info@lucumaaglass.in"
echo "  SMTP_PASSWORD=<your_actual_email_password>"
echo ""
echo "📧 Emails will be sent for:"
echo "  ✅ New user registration (welcome email)"
echo "  ✅ Job work order created"
echo "  ✅ Regular order created"
echo "  ✅ Order status changed"
echo ""
read -p "Do you want to update SMTP password now? (y/n): " response

if [ "$response" = "y" ]; then
    read -sp "Enter SMTP password: " smtp_pass
    echo ""
    
    # Update .env file
    sed -i.bak "s/^SMTP_PASSWORD=.*/SMTP_PASSWORD=$smtp_pass/" .env
    
    echo "✅ SMTP password updated!"
    echo "🔄 Restarting backend..."
    
    # Restart backend
    pkill -f "uvicorn server:app" 2>/dev/null
    nohup ./venv/bin/python -m uvicorn server:app --host 0.0.0.0 --port 8000 > /tmp/backend.log 2>&1 &
    
    sleep 2
    echo "✅ Backend restarted. Emails should now work!"
else
    echo "⏭️  Skipped. Update SMTP_PASSWORD in .env manually and restart backend."
fi

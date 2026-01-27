#!/usr/bin/env python3
"""Test SMTP email sending directly"""
import aiosmtplib
import asyncio
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

async def test_email():
    SMTP_HOST = "smtp.hostinger.com"
    SMTP_PORT = 465
    SMTP_USER = "info@lucumaaglass.in"
    SMTP_PASSWORD = "Lucumaaglass@123"
    
    try:
        message = MIMEMultipart()
        message['Subject'] = "Test Email from Glass ERP"
        message['From'] = f"Lucumaa Glass <{SMTP_USER}>"
        message['To'] = "kiranpatil86@gmail.com"
        
        html_text = "<html><body><h1>Test Email</h1><p>This is a test email from Glass ERP with PDF test</p></body></html>"
        html_part = MIMEText(html_text, 'html')
        message.attach(html_part)
        
        print(f"Connecting to {SMTP_HOST}:{SMTP_PORT}...")
        
        # Create SSL context
        ssl_context = ssl.create_default_context()
        ssl_context.check_hostname = False
        ssl_context.verify_mode = ssl.CERT_NONE
        
        await aiosmtplib.send(
            message,
            hostname=SMTP_HOST,
            port=SMTP_PORT,
            use_tls=True,
            username=SMTP_USER,
            password=SMTP_PASSWORD,
            timeout=30,
            tls_context=ssl_context
        )
        print("✅ Email sent successfully!")
        return True
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    result = asyncio.run(test_email())
    exit(0 if result else 1)

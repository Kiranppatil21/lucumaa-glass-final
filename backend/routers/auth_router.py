"""
Authentication Router - User registration, login, OTP, password reset
"""
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime, timezone, timedelta
import bcrypt
import jwt
import os
import random
import string

auth_router = APIRouter(prefix="/auth", tags=["Authentication"])

# Security
security = HTTPBearer(auto_error=False)
JWT_SECRET = os.environ.get('JWT_SECRET', 'your-secret-key-change-in-production')

# Database reference (set during initialization)
_db = None

def init_auth_router(database):
    global _db
    _db = database

def get_db():
    return _db


# =============== MODELS ===============

class UserRegister(BaseModel):
    email: EmailStr
    name: str
    phone: str
    password: str
    role: str = "customer"


class UserLogin(BaseModel):
    email: EmailStr
    password: str


# =============== HELPERS ===============

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode(), hashed.encode())


def create_token(user_id: str, email: str, role: str, name: str = "") -> str:
    payload = {
        'user_id': user_id,
        'email': email,
        'role': role,
        'name': name,
        'exp': datetime.now(timezone.utc) + timedelta(days=7)
    }
    return jwt.encode(payload, JWT_SECRET, algorithm='HS256')


def decode_token(token: str) -> dict:
    return jwt.decode(token, JWT_SECRET, algorithms=['HS256'])


async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    if not credentials:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload = decode_token(credentials.credentials)
        db = get_db()
        user = await db.users.find_one({"id": payload["user_id"]}, {"_id": 0})
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        return user
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")


def generate_otp(length: int = 6) -> str:
    return ''.join(random.choices(string.digits, k=length))


def generate_otp_email_html(otp: str, purpose: str = "verification") -> str:
    logo_url = "https://customer-assets.emergentagent.com/job_0aec802e-e67b-4582-8fac-1517907b7262/artifacts/752tez4i_Logo%20Cucumaa%20Glass.png"
    return f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #0d9488 0%, #14b8a6 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <img src="{logo_url}" alt="Lucumaa Glass" style="height: 50px; margin-bottom: 10px;">
            <h1 style="color: white; margin: 0;">LUCUMAA GLASS</h1>
            <p style="color: rgba(255,255,255,0.9); margin-top: 5px;">Premium Toughened Glass Solutions</p>
        </div>
        <div style="background: #f8fafc; padding: 30px; border-radius: 0 0 10px 10px;">
            <h2 style="color: #1e293b; margin-bottom: 20px;">Your OTP for {purpose}</h2>
            <div style="background: white; border: 2px dashed #0d9488; border-radius: 10px; padding: 20px; text-align: center; margin: 20px 0;">
                <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #0d9488;">{otp}</span>
            </div>
            <p style="color: #64748b;">This OTP is valid for 10 minutes. Do not share it with anyone.</p>
            <p style="color: #64748b; margin-top: 20px;">If you didn't request this OTP, please ignore this email.</p>
        </div>
    </div>
    """


# =============== ENDPOINTS ===============

@auth_router.post("/register")
async def register_user(user_data: UserRegister, background_tasks: BackgroundTasks = None):
    """Register a new user"""
    db = get_db()
    
    existing = await db.users.find_one({"email": user_data.email.lower()})
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    import uuid
    user_id = str(uuid.uuid4())
    
    user = {
        "id": user_id,
        "email": user_data.email.lower(),
        "name": user_data.name,
        "phone": user_data.phone,
        "password_hash": hash_password(user_data.password),
        "role": user_data.role if user_data.role in ["customer", "dealer"] else "customer",
        "is_credit_customer": False,
        "credit_limit": 0,
        "gst_number": None,
        "company_name": None,
        "wallet_balance": 0,
        "referral_code": f"LG{user_id[:6].upper()}",
        "referred_by": None,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    
    await db.users.insert_one(user)
    
    # Send welcome email
    try:
        import asyncio
        import aiosmtplib
        from email.mime.multipart import MIMEMultipart
        from email.mime.text import MIMEText
        
        async def send_welcome_email():
            try:
                SMTP_HOST = os.environ.get('SMTP_HOST', 'smtp.hostinger.com')
                SMTP_PORT = int(os.environ.get('SMTP_PORT', 465))
                SMTP_USER = os.environ.get('SMTP_USER', 'info@lucumaaglass.in')
                SMTP_PASSWORD = os.environ.get('SMTP_PASSWORD', '')
                
                if not SMTP_PASSWORD:
                    print(f"❌ SMTP not configured, skipping welcome email")
                    return
                
                welcome_html = f"""
                <!DOCTYPE html>
                <html>
                <head>
                    <style>
                        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                        .header {{ background: linear-gradient(135deg, #f97316 0%, #ea580c 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                        .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                        .button {{ display: inline-block; padding: 15px 30px; background: #f97316; color: white; text-decoration: none; border-radius: 5px; font-weight: bold; margin: 20px 0; }}
                        .features {{ background: white; padding: 20px; border-radius: 5px; margin: 20px 0; }}
                        .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="header">
                            <h1>🎉 Welcome to Lucumaa Glass!</h1>
                        </div>
                        <div class="content">
                            <p>Dear {user_data.name},</p>
                            <p>Thank you for registering with Lucumaa Glass - your trusted partner for premium toughened glass solutions!</p>
                            
                            <div class="features">
                                <h3>What you can do now:</h3>
                                <ul>
                                    <li>✅ Configure custom glass designs with our 3D tool</li>
                                    <li>✅ Get instant quotations for job work</li>
                                    <li>✅ Track your orders in real-time</li>
                                    <li>✅ Manage orders from your customer portal</li>
                                </ul>
                            </div>
                            
                            <div style="text-align: center;">
                                <a href="https://lucumaaglass.in/portal" class="button">Go to Customer Portal</a>
                            </div>
                            
                            <p>If you have any questions, feel free to contact us at info@lucumaaglass.in</p>
                            
                            <div class="footer">
                                <p>© 2026 Lucumaa Glass | Professional Glass Solutions</p>
                                <p>Contact: info@lucumaaglass.in | Phone: +91 92847 01985</p>
                            </div>
                        </div>
                    </div>
                </body>
                </html>
                """
                
                message = MIMEMultipart()
                message['Subject'] = "Welcome to Lucumaa Glass - Your Account is Ready!"
                message['From'] = f"Lucumaa Glass <{SMTP_USER}>"
                message['To'] = user_data.email
                
                html_part = MIMEText(welcome_html, 'html')
                message.attach(html_part)
                
                await aiosmtplib.send(
                    message,
                    hostname=SMTP_HOST,
                    port=SMTP_PORT,
                    use_tls=True,
                    username=SMTP_USER,
                    password=SMTP_PASSWORD
                )
                print(f"✅ Welcome email sent to {user_data.email}")
            except Exception as e:
                print(f"❌ Failed to send welcome email: {e}")
        
        asyncio.create_task(send_welcome_email())
    except Exception as e:
        print(f"Error scheduling welcome email: {e}")
    
    token = create_token(user_id, user["email"], user["role"], user["name"])
    
    return {
        "message": "Registration successful",
        "token": token,
        "user": {
            "id": user_id,
            "email": user["email"],
            "name": user["name"],
            "role": user["role"]
        }
    }


@auth_router.post("/login")
async def login_user(login_data: UserLogin):
    """Login user"""
    db = get_db()
    
    user = await db.users.find_one({"email": login_data.email.lower()}, {"_id": 0})
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    if not verify_password(login_data.password, user.get("password_hash", "")):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    token = create_token(user["id"], user["email"], user["role"], user.get("name", ""))
    
    return {
        "message": "Login successful",
        "token": token,
        "user": {
            "id": user["id"],
            "email": user["email"],
            "name": user.get("name"),
            "role": user["role"]
        }
    }


@auth_router.post("/forgot-password")
async def forgot_password(data: dict, background_tasks: BackgroundTasks):
    """Send password reset link to email"""
    db = get_db()
    email = data.get("email", "").lower()
    
    if not email:
        raise HTTPException(status_code=400, detail="Email is required")
    
    # Check if user exists
    user = await db.users.find_one({"email": email})
    if not user:
        # Don't reveal if user exists or not for security
        return {"message": "If the email is registered, you will receive a password reset link"}
    
    # Generate reset token
    import uuid
    reset_token = str(uuid.uuid4())
    expires_at = datetime.now(timezone.utc) + timedelta(hours=1)
    
    # Store reset token
    await db.password_reset_tokens.delete_many({"email": email})
    await db.password_reset_tokens.insert_one({
        "email": email,
        "token": reset_token,
        "expires_at": expires_at.isoformat(),
        "used": False,
        "created_at": datetime.now(timezone.utc).isoformat()
    })
    
    # Send reset email
    try:
        import aiosmtplib
        from email.mime.text import MIMEText
        from email.mime.multipart import MIMEMultipart
        
        SMTP_HOST = os.environ.get('SMTP_HOST', 'smtp.hostinger.com')
        SMTP_PORT = int(os.environ.get('SMTP_PORT', 465))
        SMTP_USER = os.environ.get('SMTP_USER', '')
        SMTP_PASSWORD = os.environ.get('SMTP_PASSWORD', '')
        FRONTEND_URL = os.environ.get('FRONTEND_URL', 'https://lucumaaglass.in')
        
        if SMTP_PASSWORD:
            reset_link = f"{FRONTEND_URL}/reset-password?token={reset_token}"
            
            message = MIMEMultipart('alternative')
            message['Subject'] = "Password Reset Request - Lucumaa Glass"
            message['From'] = f"Lucumaa Glass <{SMTP_USER}>"
            message['To'] = email
            
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ background: linear-gradient(135deg, #f97316 0%, #ea580c 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                    .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                    .button {{ display: inline-block; padding: 15px 30px; background: #f97316; color: white; text-decoration: none; border-radius: 5px; font-weight: bold; margin: 20px 0; }}
                    .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>🔐 Password Reset Request</h1>
                    </div>
                    <div class="content">
                        <p>Hello {user.get('name', 'User')},</p>
                        <p>We received a request to reset your password for your Lucumaa Glass account.</p>
                        <p>Click the button below to reset your password:</p>
                        <div style="text-align: center;">
                            <a href="{reset_link}" class="button">Reset Password</a>
                        </div>
                        <p><strong>This link will expire in 1 hour.</strong></p>
                        <p>If you didn't request a password reset, please ignore this email or contact support if you have concerns.</p>
                        <p>For security reasons, never share this link with anyone.</p>
                        <div class="footer">
                            <p>© 2026 Lucumaa Glass | Professional Glass Solutions</p>
                        </div>
                    </div>
                </div>
            </body>
            </html>
            """
            
            html_part = MIMEText(html_content, 'html')
            message.attach(html_part)
            
            background_tasks.add_task(
                aiosmtplib.send,
                message,
                hostname=SMTP_HOST,
                port=SMTP_PORT,
                use_tls=True,
                username=SMTP_USER,
                password=SMTP_PASSWORD
            )
    except Exception as e:
        print(f"Failed to send reset email: {e}")
    
    return {"message": "If the email is registered, you will receive a password reset link"}


@auth_router.post("/send-otp")
async def send_otp(data: dict, background_tasks: BackgroundTasks):
    """Send OTP for verification"""
    db = get_db()
    email = data.get("email", "").lower()
    purpose = data.get("purpose", "verification")
    
    if not email:
        raise HTTPException(status_code=400, detail="Email is required")
    
    otp = generate_otp()
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=10)
    
    await db.otp_codes.delete_many({"email": email})
    await db.otp_codes.insert_one({
        "email": email,
        "otp": otp,
        "purpose": purpose,
        "expires_at": expires_at.isoformat(),
        "verified": False,
        "created_at": datetime.now(timezone.utc).isoformat()
    })
    
    # Send OTP email (import from utils)
    try:
        import aiosmtplib
        from email.mime.text import MIMEText
        from email.mime.multipart import MIMEMultipart
        
        SMTP_HOST = os.environ.get('SMTP_HOST', 'smtp.hostinger.com')
        SMTP_PORT = int(os.environ.get('SMTP_PORT', 465))
        SMTP_USER = os.environ.get('SMTP_USER', '')
        SMTP_PASSWORD = os.environ.get('SMTP_PASSWORD', '')
        
        if SMTP_PASSWORD:
            message = MIMEMultipart('alternative')
            message['Subject'] = f"Your OTP for {purpose} - Lucumaa Glass"
            message['From'] = f"Lucumaa Glass <{SMTP_USER}>"
            message['To'] = email
            
            html_part = MIMEText(generate_otp_email_html(otp, purpose), 'html')
            message.attach(html_part)
            
            background_tasks.add_task(
                aiosmtplib.send,
                message,
                hostname=SMTP_HOST,
                port=SMTP_PORT,
                use_tls=True,
                username=SMTP_USER,
                password=SMTP_PASSWORD
            )
    except Exception as e:
        print(f"Failed to send OTP email: {e}")
    
    return {"message": "OTP sent successfully", "email": email}


@auth_router.post("/verify-otp")
async def verify_otp(data: dict):
    """Verify OTP"""
    db = get_db()
    email = data.get("email", "").lower()
    otp = data.get("otp", "")
    
    if not email or not otp:
        raise HTTPException(status_code=400, detail="Email and OTP are required")
    
    otp_record = await db.otp_codes.find_one({
        "email": email,
        "otp": otp,
        "verified": False
    })
    
    if not otp_record:
        raise HTTPException(status_code=400, detail="Invalid OTP")
    
    expires_at = datetime.fromisoformat(otp_record["expires_at"].replace("Z", "+00:00"))
    if datetime.now(timezone.utc) > expires_at:
        raise HTTPException(status_code=400, detail="OTP expired")
    
    await db.otp_codes.update_one(
        {"_id": otp_record["_id"]},
        {"$set": {"verified": True}}
    )
    
    # Generate reset token if purpose is password_reset
    reset_token = None
    if otp_record.get("purpose") == "password_reset":
        import uuid
        reset_token = str(uuid.uuid4())
        await db.password_reset_tokens.insert_one({
            "email": email,
            "token": reset_token,
            "expires_at": (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat(),
            "used": False
        })
    
    return {
        "message": "OTP verified successfully",
        "verified": True,
        "reset_token": reset_token
    }


@auth_router.post("/reset-password")
async def reset_password(data: dict):
    """Reset password using reset token"""
    db = get_db()
    token = data.get("token")
    new_password = data.get("new_password")
    
    if not token or not new_password:
        raise HTTPException(status_code=400, detail="Token and new password are required")
    
    reset_record = await db.password_reset_tokens.find_one({
        "token": token,
        "used": False
    })
    
    if not reset_record:
        raise HTTPException(status_code=400, detail="Invalid or expired reset token")
    
    expires_at = datetime.fromisoformat(reset_record["expires_at"].replace("Z", "+00:00"))
    if datetime.now(timezone.utc) > expires_at:
        raise HTTPException(status_code=400, detail="Reset token expired")
    
    # Update password
    await db.users.update_one(
        {"email": reset_record["email"]},
        {"$set": {"password_hash": hash_password(new_password)}}
    )
    
    # Mark token as used
    await db.password_reset_tokens.update_one(
        {"_id": reset_record["_id"]},
        {"$set": {"used": True}}
    )
    
    return {"message": "Password reset successfully"}


@auth_router.get("/me")
async def get_me(current_user: dict = Depends(get_current_user)):
    """Get current user profile"""
    return {k: v for k, v in current_user.items() if k != "password_hash"}


@auth_router.post("/create-erp-user")
async def create_erp_user(user_data: dict, current_user: dict = Depends(get_current_user)):
    """Create ERP user (admin only)"""
    if current_user.get("role") not in ["admin", "super_admin", "owner"]:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    db = get_db()
    
    existing = await db.users.find_one({"email": user_data.get("email", "").lower()})
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    import uuid
    user_id = str(uuid.uuid4())
    
    user = {
        "id": user_id,
        "email": user_data.get("email", "").lower(),
        "name": user_data.get("name"),
        "phone": user_data.get("phone", ""),
        "password_hash": hash_password(user_data.get("password", "password123")),
        "role": user_data.get("role", "operator"),
        "department": user_data.get("department"),
        "created_at": datetime.now(timezone.utc).isoformat(),
        "created_by": current_user.get("id")
    }
    
    await db.users.insert_one(user)
    
    return {"message": "User created", "user_id": user_id}


@auth_router.get("/erp-users")
async def get_erp_users(current_user: dict = Depends(get_current_user)):
    """Get all ERP users (admin only)"""
    if current_user.get("role") not in ["admin", "super_admin", "owner"]:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    db = get_db()
    users = await db.users.find(
        {"role": {"$nin": ["customer", "dealer"]}},
        {"_id": 0, "password_hash": 0}
    ).to_list(1000)
    
    return users

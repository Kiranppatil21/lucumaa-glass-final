"""
Job Work Management System
- Customer brings their own glass for toughening
- Company charges labour per sq.ft based on glass MM
- Disclaimer: Company not responsible for breakage in furnace
"""
from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import StreamingResponse
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, timezone
import uuid
import jwt
import os
import logging
import aiosmtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import asyncio
import io
import ssl

from routers.base import get_db, get_erp_user
from routers.sms import send_whatsapp

job_work_router = APIRouter(prefix="/job-work", tags=["Job Work"])

# JWT config - must match main server.py
JWT_SECRET = os.environ.get('JWT_SECRET', 'your-secret-key-change-in-production')
security = HTTPBearer()

# WhatsApp notification messages for job work status
JOB_WORK_STATUS_MESSAGES = {
    "accepted": """🔧 *Job Work Order Accepted*

Your job work order *{job_work_number}* has been accepted!

📦 Items: {total_pieces} pieces ({total_sqft} sq.ft)
💰 Amount: ₹{grand_total}

Next Step: Please bring your glass to our factory.

- Team Lucumaa Glass""",
    
    "material_received": """📦 *Material Received*

We have received your glass for Job Work Order *{job_work_number}*.

📦 Items: {total_pieces} pieces
🏭 Status: Processing will begin shortly

We will notify you once the work is completed.

- Team Lucumaa Glass""",
    
    "in_process": """🔥 *Work In Progress*

Your glass is now being processed for Job Work Order *{job_work_number}*.

⚠️ Reminder: As per the accepted disclaimer, any breakage during toughening process is not covered.

We will update you once completed.

- Team Lucumaa Glass""",
    
    "completed": """✅ *Work Completed!*

Good news! Your glass toughening for Job Work Order *{job_work_number}* is complete.

📦 Completed: {total_pieces} pieces
🏭 Status: Quality check in progress

- Team Lucumaa Glass""",
    
    "ready_for_delivery": """🚚 *Ready for Pickup/Delivery*

Your toughened glass for Job Work Order *{job_work_number}* is ready!

📦 Items: {total_pieces} pieces ({total_sqft} sq.ft)
💰 Amount Due: ₹{grand_total}

Please contact us to arrange pickup or delivery.

📞 Contact: +91-XXXXXXXXXX

- Team Lucumaa Glass""",
    
    "delivered": """🎉 *Order Delivered*

Job Work Order *{job_work_number}* has been successfully delivered.

Thank you for choosing Lucumaa Glass!

⭐ Rate us and share your experience.

- Team Lucumaa Glass"""
}

async def send_job_work_notification(phone: str, status: str, order: dict, db=None):
    """Send WhatsApp notification for job work status update"""
    if status not in JOB_WORK_STATUS_MESSAGES:
        return {"success": False, "error": "No message template for this status"}
    
    try:
        message = JOB_WORK_STATUS_MESSAGES[status].format(
            job_work_number=order.get("job_work_number", ""),
            total_pieces=order.get("summary", {}).get("total_pieces", 0),
            total_sqft=order.get("summary", {}).get("total_sqft", 0),
            grand_total=order.get("summary", {}).get("grand_total", 0)
        )
        
        result = await send_whatsapp(phone, message, db)
        logging.info(f"Job work WhatsApp sent to {phone}: {result}")
        return result
    except Exception as e:
        logging.error(f"Job work WhatsApp failed: {str(e)}")
        return {"success": False, "error": str(e)}

async def get_current_user_jw(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current user from JWT token - for job work router"""
    token = credentials.credentials
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        user_id = payload.get("user_id") or payload.get("id")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        db = get_db()
        user = await db.users.find_one({"id": user_id}, {"_id": 0, "password": 0})
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        return user
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

# Labour rates per sq.ft based on glass thickness (in MM)
DEFAULT_LABOUR_RATES = {
    "4": 8,    # 4mm - ₹8/sqft
    "5": 10,   # 5mm - ₹10/sqft
    "6": 12,   # 6mm - ₹12/sqft
    "8": 15,   # 8mm - ₹15/sqft
    "10": 18,  # 10mm - ₹18/sqft
    "12": 22,  # 12mm - ₹22/sqft
    "15": 28,  # 15mm - ₹28/sqft
    "19": 35,  # 19mm - ₹35/sqft
}

DISCLAIMER_TEXT = """
⚠️ IMPORTANT DISCLAIMER - PLEASE READ CAREFULLY ⚠️

1. The customer has provided their own glass material for toughening process.

2. Glass toughening involves heating glass to approximately 620°C and rapidly cooling it. During this process, there is an inherent risk of glass breakage due to:
   - Nickel Sulfide (NiS) inclusions in the glass
   - Pre-existing scratches, chips, or edge damage
   - Internal stresses in the original glass
   - Material defects not visible to naked eye

3. BY PROCEEDING WITH THIS JOB WORK ORDER, THE CUSTOMER ACKNOWLEDGES AND AGREES THAT:
   - Lucumaa Glass Pvt. Ltd. is NOT responsible for any glass breakage occurring during the toughening process.
   - NO compensation, replacement, or refund will be provided for any glass that breaks in the furnace.
   - The customer bears full responsibility for the quality and condition of the glass provided.

4. It is recommended that customers insure their glass material before submitting for toughening.

5. Once the glass is handed over to us, the above terms are considered accepted.

Date: {date}
Customer: {customer_name}
Job Work Order: {job_work_number}
"""

# ============ PYDANTIC MODELS ============

class JobWorkSettings(BaseModel):
    labour_rates: dict = DEFAULT_LABOUR_RATES
    gst_rate: float = 18.0
    min_order_sqft: float = 10.0
    active: bool = True

class JobWorkItem(BaseModel):
    thickness_mm: int  # 4, 5, 6, 8, 10, 12, 15, 19
    width_inch: float
    height_inch: float
    quantity: int
    notes: Optional[str] = ""
    cutouts: Optional[List[dict]] = []  # Array of cutout data (type, dimensions, position)
    design_data: Optional[dict] = None  # Complete design configuration

class JobWorkCreate(BaseModel):
    customer_name: str
    company_name: Optional[str] = ""
    phone: str
    email: Optional[str] = ""
    items: List[JobWorkItem]
    delivery_address: str
    disclaimer_accepted: bool = False
    notes: Optional[str] = ""
    # Transport fields
    transport_required: bool = False
    transport_cost: Optional[float] = 0
    transport_distance: Optional[float] = 0
    transport_location: Optional[dict] = None

class JobWorkStatusUpdate(BaseModel):
    status: str  # accepted, material_received, in_process, completed, ready_for_delivery, delivered
    notes: Optional[str] = ""
    breakage_count: Optional[int] = 0
    breakage_notes: Optional[str] = ""

class JobWorkPayment(BaseModel):
    payment_method: str  # online, cash
    amount: Optional[float] = None  # If None, pay full amount
    notes: Optional[str] = ""

class JobWorkCashPayment(BaseModel):
    order_id: str
    amount: float
    received_by: Optional[str] = ""
    notes: Optional[str] = ""

# ============ SETTINGS ============

@job_work_router.get("/settings")
async def get_job_work_settings(current_user: dict = Depends(get_erp_user)):
    """Get job work settings"""
    db = get_db()
    settings = await db.job_work_settings.find_one({}, {"_id": 0})
    if not settings:
        settings = JobWorkSettings().model_dump()
    return settings

@job_work_router.put("/settings")
async def update_job_work_settings(
    settings: JobWorkSettings,
    current_user: dict = Depends(get_erp_user)
):
    """Update job work settings (Admin only)"""
    if current_user.get("role") not in ["super_admin", "admin"]:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    db = get_db()
    doc = settings.model_dump()
    doc["updated_by"] = current_user.get("name", "")
    doc["updated_at"] = datetime.now(timezone.utc).isoformat()
    
    await db.job_work_settings.update_one({}, {"$set": doc}, upsert=True)
    return {"message": "Settings updated", "settings": doc}

@job_work_router.get("/labour-rates")
async def get_labour_rates():
    """Get labour rates per sq.ft (public) - from centralized settings"""
    db = get_db()
    # First try to get from new centralized job_work_pricing settings
    pricing_settings = await db.settings.find_one({"type": "job_work_pricing"}, {"_id": 0})
    if pricing_settings and "labour_rates" in pricing_settings:
        return {"labour_rates": pricing_settings["labour_rates"]}
    
    # Fallback to old job_work_settings
    settings = await db.job_work_settings.find_one({}, {"_id": 0, "labour_rates": 1})
    rates = settings.get("labour_rates", DEFAULT_LABOUR_RATES) if settings else DEFAULT_LABOUR_RATES
    return {"labour_rates": rates}

# ============ CALCULATE COST ============

@job_work_router.post("/calculate")
async def calculate_job_work_cost(items: List[JobWorkItem]):
    """Calculate job work cost based on items - uses centralized pricing settings"""
    db = get_db()
    
    # Get pricing from centralized settings
    pricing_settings = await db.settings.find_one({"type": "job_work_pricing"}, {"_id": 0})
    if pricing_settings:
        labour_rates = pricing_settings.get("labour_rates", DEFAULT_LABOUR_RATES)
        gst_rate = pricing_settings.get("gst_rate", 18.0)
    else:
        # Fallback to old settings
        settings = await db.job_work_settings.find_one({}, {"_id": 0})
        labour_rates = settings.get("labour_rates", DEFAULT_LABOUR_RATES) if settings else DEFAULT_LABOUR_RATES
        gst_rate = settings.get("gst_rate", 18.0) if settings else 18.0
    
    item_details = []
    total_sqft = 0
    total_labour = 0
    
    for item in items:
        # Calculate sq.ft (width x height in inches / 144)
        sqft_per_piece = (item.width_inch * item.height_inch) / 144
        total_sqft_item = sqft_per_piece * item.quantity
        
        # Get labour rate for this thickness
        rate_key = str(item.thickness_mm)
        labour_rate = labour_rates.get(rate_key, 15)  # Default ₹15/sqft
        
        labour_cost = round(total_sqft_item * labour_rate, 2)
        
        item_details.append({
            "thickness_mm": item.thickness_mm,
            "width_inch": item.width_inch,
            "height_inch": item.height_inch,
            "quantity": item.quantity,
            "sqft_per_piece": round(sqft_per_piece, 2),
            "total_sqft": round(total_sqft_item, 2),
            "labour_rate": labour_rate,
            "labour_cost": labour_cost
        })
        
        total_sqft += total_sqft_item
        total_labour += labour_cost
    
    # Calculate GST
    gst_amount = round(total_labour * gst_rate / 100, 2)
    grand_total = round(total_labour + gst_amount, 2)
    
    return {
        "items": item_details,
        "summary": {
            "total_sqft": round(total_sqft, 2),
            "total_pieces": sum(i.quantity for i in items),
            "labour_charges": total_labour,
            "gst_rate": gst_rate,
            "gst_amount": gst_amount,
            "grand_total": grand_total
        }
    }

# ============ CREATE JOB WORK ORDER ============

async def generate_job_work_number():
    """Generate unique job work number like JW-YYYYMMDD-XXXX"""
    db = get_db()
    today = datetime.now(timezone.utc).strftime("%Y%m%d")
    prefix = f"JW-{today}-"
    
    # Find latest job work number for today
    latest = await db.job_work_orders.find_one(
        {"job_work_number": {"$regex": f"^{prefix}"}},
        sort=[("job_work_number", -1)]
    )
    
    if latest:
        last_num = int(latest["job_work_number"].split("-")[-1])
        new_num = last_num + 1
    else:
        new_num = 1
    
    return f"{prefix}{new_num:04d}"


def generate_job_work_pdf(order: dict) -> bytes:
    """Generate a concise job work PDF with items and summary."""
    from reportlab.lib.pagesizes import A4
    from reportlab.lib import colors
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
    from reportlab.lib.units import mm

    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=20 * mm, leftMargin=20 * mm, topMargin=20 * mm, bottomMargin=20 * mm)

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        'JWTitle', parent=styles['Heading1'], fontSize=18, textColor=colors.HexColor('#7c3aed'), alignment=1, spaceAfter=8 * mm
    )

    elements = [Paragraph("Job Work Specification", title_style), Spacer(1, 4 * mm)]

    summary_rows = [
        ["Job Work Number", order.get('job_work_number', '')],
        ["Customer", order.get('customer_name', '')],
        ["Phone", order.get('phone', '')],
        ["Email", order.get('email', '')],
        ["Pieces", str(order.get('summary', {}).get('total_pieces', 0))],
        ["Total Sq.Ft", str(order.get('summary', {}).get('total_sqft', 0))],
        ["Grand Total", f"₹{order.get('summary', {}).get('grand_total', 0):,}"],
    ]

    summary_table = Table(summary_rows, colWidths=[50 * mm, 110 * mm])
    summary_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#ede9fe')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor('#5b21b6')),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#ddd')),
    ]))
    elements.append(summary_table)
    elements.append(Spacer(1, 6 * mm))

    # Items table
    items = order.get('item_details', [])
    if items:
        table_data = [[
            "Thickness (mm)", "Width (inch)", "Height (inch)", "Qty", "Sq.Ft/pc", "Labour ₹"
        ]]
        for item in items:
            table_data.append([
                item.get('thickness_mm', ''),
                item.get('width_inch', ''),
                item.get('height_inch', ''),
                item.get('quantity', ''),
                item.get('sqft_per_piece', ''),
                item.get('labour_cost', ''),
            ])
        items_table = Table(table_data, colWidths=[30 * mm, 25 * mm, 25 * mm, 20 * mm, 30 * mm, 30 * mm])
        items_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#f5f3ff')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor('#4c1d95')),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#ddd')),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTSIZE', (0, 0), (-1, -1), 9),
        ]))
        elements.append(Paragraph("Items", styles['Heading3']))
        elements.append(items_table)
        elements.append(Spacer(1, 4 * mm))

    disclaimer = Paragraph(
        "<b>Disclaimer:</b> Company not responsible for breakage during toughening. No compensation or refund for broken glass.",
        styles['Normal']
    )
    elements.append(disclaimer)

    doc.build(elements)
    buffer.seek(0)
    return buffer.read()

async def send_job_work_email(order: dict):
    """Send email confirmation for job work order"""
    try:
        SMTP_HOST = os.environ.get('SMTP_HOST', 'smtp.hostinger.com')
        SMTP_PORT = int(os.environ.get('SMTP_PORT', 465))
        SMTP_USER = os.environ.get('SMTP_USER', 'info@lucumaaglass.in')
        SMTP_PASSWORD = os.environ.get('SMTP_PASSWORD', 'Info123@@123')
        
        if not SMTP_PASSWORD or not order.get('email'):
            logging.warning(f"Cannot send email - SMTP not configured or no email address")
            return
        
        email_html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                .order-details {{ background: white; padding: 20px; border-radius: 5px; margin: 20px 0; }}
                .detail-row {{ display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #eee; }}
                .total {{ font-size: 18px; font-weight: bold; color: #8b5cf6; }}
                .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
                .warning {{ background: #fef3c7; border-left: 4px solid #f59e0b; padding: 15px; margin: 20px 0; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🔨 Job Work Order Confirmed!</h1>
                    <p>Your glass toughening order is confirmed</p>
                </div>
                <div class="content">
                    <p>Dear {order['customer_name']},</p>
                    <p>Your job work order has been successfully placed and confirmed!</p>
                    
                    <div class="order-details">
                        <h3>Job Work Details</h3>
                        <div class="detail-row">
                            <span>Job Work Number:</span>
                            <strong>{order['job_work_number']}</strong>
                        </div>
                        <div class="detail-row">
                            <span>Total Pieces:</span>
                            <span>{order['summary']['total_pieces']} pcs</span>
                        </div>
                        <div class="detail-row">
                            <span>Total Area:</span>
                            <span>{order['summary']['total_sqft']} sq.ft</span>
                        </div>
                        <div class="detail-row total">
                            <span>Grand Total:</span>
                            <span>₹{order['summary']['grand_total']:,}</span>
                        </div>
                        <div class="detail-row">
                            <span>Advance Required ({order['advance_percent']}%):</span>
                            <strong style="color: #ef4444;">₹{order['advance_required']:,}</strong>
                        </div>
                    </div>
                    
                    <div class="warning">
                        <strong>⚠️ Important: Advance Payment Required</strong>
                        <p style="margin: 5px 0 0 0;">Please pay the advance amount before bringing your glass for processing.</p>
                    </div>
                    
                    <p><strong>📋 Items in Your Order:</strong></p>
                    <ul>
                        {''.join([f"<li>{item['quantity']} pcs - {item['thickness_mm']}mm glass ({item['width_inch']}\" × {item['height_inch']}\") - ₹{item['labour_cost']}</li>" for item in order['item_details']])}
                    </ul>
                    
                    <p>Our team will contact you shortly to confirm the delivery schedule.</p>
                    
                    <p style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
                        <strong>Next Steps:</strong><br/>
                        1. Pay advance amount<br/>
                        2. Bring your glass to our facility<br/>
                        3. We'll process and notify you when ready
                    </p>
                    
                    <div class="footer">
                        <p>© 2026 Lucumaa Glass | Professional Glass Solutions</p>
                        <p>Contact: info@lucumaaglass.in</p>
                    </div>
                </div>
            </div>
        </body>
        </html>
        """
        
        message = MIMEMultipart()
        message['Subject'] = f"Job Work Order Confirmed - {order['job_work_number']} | Lucumaa Glass"
        message['From'] = f"Lucumaa Glass <{SMTP_USER}>"
        message['To'] = order['email']
        
        html_part = MIMEText(email_html, 'html')
        message.attach(html_part)
        
        # Generate and attach PDF inline (no external service dependency)
        try:
            from email.mime.application import MIMEApplication
            pdf_bytes = generate_job_work_pdf(order)
            pdf_attachment = MIMEApplication(pdf_bytes, _subtype='pdf')
            pdf_attachment.add_header(
                'Content-Disposition', 
                'attachment', 
                filename=f'job_work_{order["job_work_number"]}.pdf'
            )
            message.attach(pdf_attachment)
            logging.info("✅ PDF attached to job work email")
        except Exception as pdf_error:
            logging.warning(f"⚠️ Could not attach PDF to email: {str(pdf_error)}")
        
        # Create SSL context to tolerate host cert issues (Hostinger)
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
        logging.info(f"✅ Job work email sent successfully to {order['email']}")
    except Exception as e:
        logging.error(f"❌ Failed to send job work email: {str(e)}")

@job_work_router.post("/orders")
async def create_job_work_order(
    data: JobWorkCreate,
    current_user: dict = Depends(get_current_user_jw)
):
    """Create new job work order"""
    if not data.disclaimer_accepted:
        raise HTTPException(
            status_code=400, 
            detail="You must accept the disclaimer before proceeding. Glass breakage during toughening is not company's responsibility."
        )
    
    if not data.items:
        raise HTTPException(status_code=400, detail="At least one item is required")
    
    db = get_db()
    
    # Calculate costs
    calc_result = await calculate_job_work_cost(data.items)
    
    # Generate job work number
    job_work_number = await generate_job_work_number()
    
    # Calculate advance payment requirement
    # 1 piece = 100% advance, 2+ pieces = 50% advance
    total_pieces = calc_result["summary"]["total_pieces"]
    labour_total = calc_result["summary"]["grand_total"]
    
    # Add transport cost if required
    transport_cost = data.transport_cost if data.transport_required else 0
    grand_total = labour_total + transport_cost
    
    if total_pieces == 1:
        advance_percent = 100
        advance_required = grand_total
    else:
        advance_percent = 50
        advance_required = round(grand_total * 0.5, 2)
    
    # Update summary with transport
    summary = calc_result["summary"].copy()
    summary["transport_cost"] = transport_cost
    summary["grand_total"] = grand_total
    
    # Create order document
    order = {
        "id": str(uuid.uuid4()),
        "job_work_number": job_work_number,
        "user_id": current_user.get("id"),
        "customer_name": data.customer_name,
        "company_name": data.company_name,
        "phone": data.phone,
        "email": data.email or current_user.get("email", ""),
        "items": [item.model_dump() for item in data.items],
        "item_details": calc_result["items"],
        "summary": summary,
        "delivery_address": data.delivery_address,
        "notes": data.notes,
        "disclaimer_accepted": True,
        "disclaimer_accepted_at": datetime.now(timezone.utc).isoformat(),
        "status": "pending",  # pending -> accepted -> material_received -> in_process -> completed -> ready_for_delivery -> delivered
        "status_history": [
            {
                "status": "pending",
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "by": current_user.get("name", ""),
                "notes": "Job work order created"
            }
        ],
        "breakage_count": 0,
        "breakage_notes": "",
        "payment_status": "pending",  # pending, partial, completed
        "advance_percent": advance_percent,
        "advance_required": advance_required,
        "advance_paid": 0,
        "remaining_amount": grand_total,
        # Transport fields
        "transport_required": data.transport_required,
        "transport_cost": transport_cost,
        "transport_distance": data.transport_distance,
        "transport_location": data.transport_location,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat()
    }
    
    await db.job_work_orders.insert_one(order)
    
    # Send email confirmation asynchronously
    asyncio.create_task(send_job_work_email(order))
    
    # Return without _id
    if "_id" in order:
        del order["_id"]
    
    return {
        "message": "Job work order created successfully",
        "job_work_number": job_work_number,
        "order": order,
        "advance_payment": {
            "percent": advance_percent,
            "amount": advance_required,
            "note": "100% advance for single piece, 50% for 2+ pieces"
        },
        "disclaimer": DISCLAIMER_TEXT.format(
            date=datetime.now(timezone.utc).strftime("%d-%m-%Y"),
            customer_name=data.customer_name,
            job_work_number=job_work_number
        )
    }

# ============ GET JOB WORK ORDERS ============

@job_work_router.get("/orders")
async def get_job_work_orders(
    page: int = 1,
    limit: int = 10,
    status: Optional[str] = None,
    search: Optional[str] = None,
    current_user: dict = Depends(get_erp_user)
):
    """Get all job work orders (Admin) with pagination"""
    db = get_db()
    query = {}
    if status:
        query["status"] = status
    
    if search:
        import re
        search_pattern = re.escape(search.strip())
        query["$or"] = [
            {"order_number": {"$regex": search_pattern, "$options": "i"}},
            {"customer_name": {"$regex": search_pattern, "$options": "i"}},
            {"customer_phone": {"$regex": search_pattern, "$options": "i"}}
        ]
    
    # Pagination
    limit = min(limit, 200)  # Max 200 per page
    skip = (page - 1) * limit
    
    total = await db.job_work_orders.count_documents(query)
    orders = await db.job_work_orders.find(query, {"_id": 0}).sort("created_at", -1).skip(skip).limit(limit).to_list(limit)
    
    return {
        "orders": orders,
        "total": total,
        "page": page,
        "limit": limit,
        "total_pages": (total + limit - 1) // limit
    }

@job_work_router.get("/my-orders")
async def get_my_job_work_orders(current_user: dict = Depends(get_current_user_jw)):
    """Get customer's own job work orders"""
    db = get_db()
    orders = await db.job_work_orders.find(
        {"user_id": current_user.get("id")},
        {"_id": 0}
    ).sort("created_at", -1).to_list(100)
    return orders

@job_work_router.get("/orders/{order_id}")
async def get_job_work_order(order_id: str, current_user: dict = Depends(get_current_user_jw)):
    """Get single job work order"""
    db = get_db()
    order = await db.job_work_orders.find_one({"id": order_id}, {"_id": 0})
    if not order:
        raise HTTPException(status_code=404, detail="Job work order not found")
    
    # Check access - either owner or admin
    if order["user_id"] != current_user.get("id") and current_user.get("role") not in ["admin", "super_admin", "manager"]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    return order


@job_work_router.get("/orders/{order_id}/pdf")
async def download_job_work_pdf(order_id: str, current_user: dict = Depends(get_erp_user)):
    """Download job work PDF (admin/super_admin)."""
    db = get_db()
    order = await db.job_work_orders.find_one({"id": order_id}, {"_id": 0})
    if not order:
        raise HTTPException(status_code=404, detail="Job work order not found")

    pdf_bytes = generate_job_work_pdf(order)
    filename = f"job_work_{order.get('job_work_number', order_id)}.pdf"
    return StreamingResponse(
        io.BytesIO(pdf_bytes),
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

@job_work_router.get("/orders/{order_id}/design-pdf")
async def download_job_work_design_pdf(order_id: str, current_user: dict = Depends(get_erp_user)):
    """Download job work design PDF with cutouts/3D design (admin/super_admin)."""
    from routers.glass_configurator import export_pdf, PDFExportRequest, GlassExportSpec, CutoutExportSpec
    
    db = get_db()
    order = await db.job_work_orders.find_one({"id": order_id}, {"_id": 0})
    if not order:
        raise HTTPException(status_code=404, detail="Job work order not found")
    
    # Check if order has design data - look in first item or at order level
    items = order.get('items', [])
    if not items:
        raise HTTPException(status_code=404, detail="No items found in order")
    
    first_item = items[0]
    design_data = first_item.get('design_data') or order.get('design_data')
    cutouts_data = first_item.get('cutouts', []) or order.get('cutouts', [])
    
    if not cutouts_data or len(cutouts_data) == 0:
        raise HTTPException(status_code=404, detail="No design data found for this job work order. Design PDF is only available for orders created from the 3D configurator with cutouts.")
    
    # Build glass config from job work data
    width_mm = design_data.get('width_mm') if design_data else round(float(first_item.get('width_inch', 0)) * 25.4)
    height_mm = design_data.get('height_mm') if design_data else round(float(first_item.get('height_inch', 0)) * 25.4)
    thickness_mm = design_data.get('thickness_mm') if design_data else first_item.get('thickness_mm', 8)
    
    glass_config = GlassExportSpec(
        width_mm=width_mm,
        height_mm=height_mm,
        thickness_mm=thickness_mm,
        glass_type=f"Job Work - {design_data.get('job_work_type', 'Toughening') if design_data else 'Toughening'}",
        color_name="Clear",
        application="Job Work Order"
    )
    
    # Map cutouts to export format
    cutout_shapes = ['SH', 'R', 'T', 'HX', 'HR', 'ST', 'PT', 'OV', 'DM', 'OC']
    shape_names = {
        'SH': 'Hole', 'R': 'Rectangle', 'T': 'Triangle', 'HX': 'Hexagon',
        'HR': 'Heart', 'ST': 'Star', 'PT': 'Pentagon', 'OV': 'Oval',
        'DM': 'Diamond', 'OC': 'Octagon'
    }
    shape_labels = {
        'SH': 'H', 'R': 'R', 'T': 'T', 'HX': 'HX',
        'HR': 'HR', 'ST': 'ST', 'PT': 'PT', 'OV': 'OV',
        'DM': 'DM', 'OC': 'OC'
    }
    
    cutouts_export = []
    for idx, cutout in enumerate(cutouts_data, 1):
        cutout_type = cutout.get('type', 'SH')
        label = shape_labels.get(cutout_type, 'C')
        
        # Calculate bounds
        diameter = cutout.get('diameter', 50)
        width = cutout.get('width', 100)
        height = cutout.get('height', 80)
        x = cutout.get('x', width_mm / 2)
        y = cutout.get('y', height_mm / 2)
        rotation = cutout.get('rotation', 0)
        
        # Calculate edge distances
        if cutout_type in ['SH', 'HX', 'HR', 'ST', 'PT', 'OC']:
            half_size = diameter / 2
            half_height = half_size
        else:
            half_size = width / 2
            half_height = height / 2
        
        left_edge = max(0, round(x - half_size))
        right_edge = max(0, round(width_mm - x - half_size))
        top_edge = max(0, round(height_mm - y - half_height))
        bottom_edge = max(0, round(y - half_height))
        
        cutouts_export.append(CutoutExportSpec(
            number=f"{label}{idx}",
            type=shape_names.get(cutout_type, 'Unknown'),
            diameter=diameter if cutout_type in ['SH', 'HX', 'HR', 'ST', 'PT', 'OC'] else None,
            width=width if cutout_type not in ['SH', 'HX', 'HR', 'ST', 'PT', 'OC'] else None,
            height=height if cutout_type not in ['SH', 'HX', 'HR', 'ST', 'PT', 'OC'] else None,
            x=x,
            y=y,
            rotation=rotation,
            left_edge=left_edge,
            right_edge=right_edge,
            top_edge=top_edge,
            bottom_edge=bottom_edge
        ))
    
    pdf_request = PDFExportRequest(
        glass_config=glass_config,
        cutouts=cutouts_export,
        quantity=order.get('summary', {}).get('total_pieces', 1)
    )
    
    # Generate PDF using existing glass configurator export
    return await export_pdf(pdf_request, current_user)

# ============ UPDATE STATUS ============

@job_work_router.patch("/orders/{order_id}/status")
async def update_job_work_status(
    order_id: str,
    update: JobWorkStatusUpdate,
    current_user: dict = Depends(get_erp_user)
):
    """Update job work order status (Admin only)"""
    db = get_db()
    
    order = await db.job_work_orders.find_one({"id": order_id}, {"_id": 0})
    if not order:
        raise HTTPException(status_code=404, detail="Job work order not found")
    
    valid_statuses = ["accepted", "material_received", "in_process", "completed", "ready_for_delivery", "delivered", "cancelled"]
    if update.status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Invalid status. Valid: {valid_statuses}")
    
    # Add to status history
    status_entry = {
        "status": update.status,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "by": current_user.get("name", ""),
        "notes": update.notes or ""
    }
    
    update_doc = {
        "status": update.status,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }
    
    # Handle breakage
    if update.breakage_count and update.breakage_count > 0:
        update_doc["breakage_count"] = order.get("breakage_count", 0) + update.breakage_count
        update_doc["breakage_notes"] = (order.get("breakage_notes", "") + "\n" + update.breakage_notes).strip() if update.breakage_notes else order.get("breakage_notes", "")
    
    await db.job_work_orders.update_one(
        {"id": order_id},
        {
            "$set": update_doc,
            "$push": {"status_history": status_entry}
        }
    )
    
    # Get updated order for email notification
    updated_order = await db.job_work_orders.find_one({"id": order_id}, {"_id": 0})
    
    # Send email notification to customer
    customer_email = order.get("email") or order.get("customer_email")
    if customer_email:
        try:
            from routers.notifications import notify_job_work_status_change, notify_job_work_completed
            
            # Send status change email
            await notify_job_work_status_change(updated_order or order, customer_email)
            
            # Send completion email if status is "completed"
            if update.status == "completed":
                await notify_job_work_completed(updated_order or order, customer_email)
                
        except Exception as e:
            logging.error(f"Failed to send job work email notification: {str(e)}")
    
    # Send WhatsApp notification to customer
    if order.get("phone"):
        # Get updated order for notification
        updated_order = await db.job_work_orders.find_one({"id": order_id}, {"_id": 0})
        notification_result = await send_job_work_notification(
            order["phone"], 
            update.status, 
            updated_order or order,
            db
        )
        logging.info(f"Job work notification for {order_id}: {notification_result}")
    
    return {"message": f"Status updated to {update.status}", "status": update.status, "notification_sent": bool(customer_email)}

# ============ DASHBOARD STATS ============

@job_work_router.get("/dashboard")
async def get_job_work_dashboard(current_user: dict = Depends(get_erp_user)):
    """Get job work dashboard stats"""
    db = get_db()
    
    # Count by status
    pipeline = [
        {"$group": {"_id": "$status", "count": {"$sum": 1}}}
    ]
    status_counts = await db.job_work_orders.aggregate(pipeline).to_list(20)
    status_dict = {s["_id"]: s["count"] for s in status_counts}
    
    # Total orders
    total = await db.job_work_orders.count_documents({})
    
    # Pending orders
    pending = await db.job_work_orders.count_documents({"status": {"$in": ["pending", "accepted", "material_received", "in_process"]}})
    
    # This month stats
    from datetime import timedelta
    month_start = datetime.now(timezone.utc).replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    month_orders = await db.job_work_orders.count_documents({"created_at": {"$gte": month_start.isoformat()}})
    
    # Total breakage
    breakage_pipeline = [
        {"$group": {"_id": None, "total": {"$sum": "$breakage_count"}}}
    ]
    breakage_result = await db.job_work_orders.aggregate(breakage_pipeline).to_list(1)
    total_breakage = breakage_result[0]["total"] if breakage_result else 0
    
    return {
        "total_orders": total,
        "pending_orders": pending,
        "this_month": month_orders,
        "total_breakage": total_breakage,
        "by_status": status_dict,
        "labour_rates": DEFAULT_LABOUR_RATES
    }

# ============ DISCLAIMER ============

@job_work_router.get("/disclaimer")
async def get_disclaimer():
    """Get disclaimer text"""
    return {
        "disclaimer": DISCLAIMER_TEXT.format(
            date="{date}",
            customer_name="{customer_name}",
            job_work_number="{job_work_number}"
        ),
        "summary_points": [
            "Company NOT responsible for glass breakage in furnace",
            "NO compensation or refund for broken glass",
            "Customer bears full responsibility for glass quality",
            "Terms accepted upon material handover"
        ]
    }

# ============ PAYMENT APIS ============

@job_work_router.post("/orders/{order_id}/initiate-payment")
async def initiate_job_work_payment(
    order_id: str,
    current_user: dict = Depends(get_current_user_jw)
):
    """Initiate online payment for job work order (advance or remaining)"""
    import razorpay
    
    db = get_db()
    order = await db.job_work_orders.find_one({"id": order_id}, {"_id": 0})
    
    if not order:
        raise HTTPException(status_code=404, detail="Job work order not found")
    
    if order["user_id"] != current_user.get("id"):
        raise HTTPException(status_code=403, detail="Access denied")
    
    if order.get("payment_status") == "completed":
        raise HTTPException(status_code=400, detail="Payment already completed")
    
    # Determine payment amount
    # If advance not paid, pay advance amount. Otherwise pay remaining.
    advance_paid = order.get("advance_paid", 0)
    advance_required = order.get("advance_required", order["summary"]["grand_total"])
    grand_total = order["summary"]["grand_total"]
    
    if advance_paid < advance_required:
        # Pay advance amount
        amount = advance_required - advance_paid
        payment_type = "advance"
    else:
        # Pay remaining amount
        amount = grand_total - advance_paid
        payment_type = "remaining"
    
    if amount <= 0:
        raise HTTPException(status_code=400, detail="No payment required")
    
    amount_paise = int(amount * 100)
    
    # Create Razorpay order
    razorpay_key = os.environ.get("RAZORPAY_KEY_ID")
    razorpay_secret = os.environ.get("RAZORPAY_KEY_SECRET")
    
    if not razorpay_key or not razorpay_secret:
        raise HTTPException(status_code=500, detail="Payment gateway not configured")
    
    client = razorpay.Client(auth=(razorpay_key, razorpay_secret))
    
    razorpay_order = client.order.create({
        "amount": amount_paise,
        "currency": "INR",
        "payment_capture": 1,
        "notes": {
            "job_work_number": order["job_work_number"],
            "order_id": order_id,
            "payment_type": payment_type
        }
    })
    
    # Store razorpay order id and payment type
    await db.job_work_orders.update_one(
        {"id": order_id},
        {"$set": {
            "razorpay_order_id": razorpay_order["id"],
            "pending_payment_type": payment_type,
            "pending_payment_amount": amount
        }}
    )
    
    return {
        "razorpay_order_id": razorpay_order["id"],
        "amount": amount_paise,
        "amount_rupees": amount,
        "currency": "INR",
        "job_work_number": order["job_work_number"],
        "payment_type": payment_type,
        "advance_percent": order.get("advance_percent", 100)
    }

@job_work_router.post("/orders/{order_id}/verify-payment")
async def verify_job_work_payment(
    order_id: str,
    razorpay_payment_id: str,
    razorpay_signature: str,
    current_user: dict = Depends(get_current_user_jw)
):
    """Verify online payment for job work order"""
    import razorpay
    import hmac
    import hashlib
    
    db = get_db()
    order = await db.job_work_orders.find_one({"id": order_id}, {"_id": 0})
    
    if not order:
        raise HTTPException(status_code=404, detail="Job work order not found")
    
    razorpay_key = os.environ.get("RAZORPAY_KEY_ID")
    razorpay_secret = os.environ.get("RAZORPAY_KEY_SECRET")
    
    # Verify signature
    razorpay_order_id = order.get("razorpay_order_id")
    message = f"{razorpay_order_id}|{razorpay_payment_id}"
    expected_signature = hmac.new(
        razorpay_secret.encode(),
        message.encode(),
        hashlib.sha256
    ).hexdigest()
    
    if expected_signature != razorpay_signature:
        raise HTTPException(status_code=400, detail="Payment verification failed")
    
    # Get payment details
    payment_type = order.get("pending_payment_type", "advance")
    payment_amount = order.get("pending_payment_amount", 0)
    current_advance_paid = order.get("advance_paid", 0)
    grand_total = order["summary"]["grand_total"]
    
    # Update payment amounts
    new_advance_paid = current_advance_paid + payment_amount
    new_remaining = grand_total - new_advance_paid
    
    # Determine payment status
    if new_remaining <= 0:
        payment_status = "completed"
    else:
        payment_status = "partially_paid"
    
    # Update payment status
    await db.job_work_orders.update_one(
        {"id": order_id},
        {
            "$set": {
                "payment_status": payment_status,
                "payment_method": "online",
                "razorpay_payment_id": razorpay_payment_id,
                "advance_paid": new_advance_paid,
                "remaining_amount": new_remaining,
                "paid_at": datetime.now(timezone.utc).isoformat(),
                "updated_at": datetime.now(timezone.utc).isoformat()
            }
        }
    )
    
    return {
        "message": "Payment verified successfully", 
        "status": payment_status,
        "advance_paid": new_advance_paid,
        "remaining": new_remaining
    }

@job_work_router.post("/orders/{order_id}/cash-payment")
async def mark_job_work_cash_payment(
    order_id: str,
    payment: JobWorkCashPayment,
    current_user: dict = Depends(get_erp_user)
):
    """Mark cash payment received for job work order (Admin/Finance only)"""
    if current_user.get("role") not in ["super_admin", "admin", "finance", "hr"]:
        raise HTTPException(status_code=403, detail="Admin/Finance access required")
    
    db = get_db()
    order = await db.job_work_orders.find_one({"id": order_id}, {"_id": 0})
    
    if not order:
        raise HTTPException(status_code=404, detail="Job work order not found")
    
    if order.get("payment_status") == "completed":
        raise HTTPException(status_code=400, detail="Payment already completed")
    
    expected_amount = order["summary"]["grand_total"]
    if payment.amount < expected_amount:
        raise HTTPException(status_code=400, detail=f"Full payment required. Expected: ₹{expected_amount}")
    
    # Update payment status
    await db.job_work_orders.update_one(
        {"id": order_id},
        {
            "$set": {
                "payment_status": "completed",
                "payment_method": "cash",
                "paid_amount": payment.amount,
                "cash_received_by": payment.received_by or current_user.get("name", ""),
                "cash_payment_notes": payment.notes,
                "paid_at": datetime.now(timezone.utc).isoformat(),
                "updated_at": datetime.now(timezone.utc).isoformat()
            }
        }
    )
    
    # Send WhatsApp notification
    if order.get("phone"):
        message = f"""✅ *Payment Received*

Your payment of ₹{payment.amount} for Job Work Order *{order['job_work_number']}* has been received.

Thank you for your payment!

- Team Lucumaa Glass"""
        await send_whatsapp(order["phone"], message, db)
    
    return {"message": "Cash payment recorded successfully", "status": "completed"}

@job_work_router.post("/orders/{order_id}/set-cash-preference")
async def set_job_work_cash_preference(
    order_id: str,
    current_user: dict = Depends(get_current_user_jw)
):
    """Customer indicates they will pay by cash"""
    db = get_db()
    order = await db.job_work_orders.find_one({"id": order_id}, {"_id": 0})
    
    if not order:
        raise HTTPException(status_code=404, detail="Job work order not found")
    
    if order["user_id"] != current_user.get("id"):
        raise HTTPException(status_code=403, detail="Access denied")
    
    await db.job_work_orders.update_one(
        {"id": order_id},
        {"$set": {"payment_preference": "cash", "updated_at": datetime.now(timezone.utc).isoformat()}}
    )
    
    return {"message": "Cash payment preference saved. Please pay at our office or to delivery person."}

# ============ REVENUE STATS FOR P&L ============

@job_work_router.get("/revenue-stats")
async def get_job_work_revenue_stats(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    current_user: dict = Depends(get_erp_user)
):
    """Get job work revenue stats for P&L reports"""
    if current_user.get("role") not in ["super_admin", "admin", "finance", "owner"]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    db = get_db()
    
    # Build query
    query = {"payment_status": "completed"}
    if start_date:
        query["paid_at"] = {"$gte": start_date}
    if end_date:
        if "paid_at" in query:
            query["paid_at"]["$lte"] = end_date
        else:
            query["paid_at"] = {"$lte": end_date}
    
    # Get completed orders
    orders = await db.job_work_orders.find(query, {"_id": 0}).to_list(1000)
    
    # Calculate totals
    total_revenue = sum(o.get("paid_amount", 0) for o in orders)
    total_orders = len(orders)
    total_sqft = sum(o.get("summary", {}).get("total_sqft", 0) for o in orders)
    total_pieces = sum(o.get("summary", {}).get("total_pieces", 0) for o in orders)
    total_gst = sum(o.get("summary", {}).get("gst_amount", 0) for o in orders)
    
    # Monthly breakdown
    monthly = {}
    for o in orders:
        paid_at = o.get("paid_at", o.get("created_at", ""))
        if paid_at:
            month = paid_at[:7]  # YYYY-MM
            if month not in monthly:
                monthly[month] = {"revenue": 0, "orders": 0, "sqft": 0}
            monthly[month]["revenue"] += o.get("paid_amount", 0)
            monthly[month]["orders"] += 1
            monthly[month]["sqft"] += o.get("summary", {}).get("total_sqft", 0)
    
    # Payment method breakdown
    by_payment_method = {"online": 0, "cash": 0}
    for o in orders:
        method = o.get("payment_method", "unknown")
        if method in by_payment_method:
            by_payment_method[method] += o.get("paid_amount", 0)
    
    return {
        "total_revenue": round(total_revenue, 2),
        "total_orders": total_orders,
        "total_sqft": round(total_sqft, 2),
        "total_pieces": total_pieces,
        "total_gst": round(total_gst, 2),
        "net_revenue": round(total_revenue - total_gst, 2),
        "monthly_breakdown": monthly,
        "by_payment_method": by_payment_method
    }


"""
Orders Router - Order creation, payment, dispatch management
With Auto-posting to Party Ledger & GL
"""
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, UploadFile, File
from pydantic import BaseModel, EmailStr
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone, timedelta
import os
import uuid
import razorpay
import hmac
import hashlib
import io
import logging
import aiosmtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication

orders_router = APIRouter(prefix="/orders", tags=["Orders"])

# Database reference
_db = None

def init_orders_router(database):
    global _db
    _db = database

def get_db():
    return _db

# Import auth dependency
from .auth_router import get_current_user

# Import ledger auto-post function
async def auto_post_to_ledger_orders(db, **kwargs):
    """Safe import and call ledger auto-post"""
    try:
        from .ledger import auto_post_to_ledger
        await auto_post_to_ledger(db, **kwargs)
    except Exception as e:
        print(f"Ledger auto-post failed: {e}")

# Razorpay client
RAZORPAY_KEY_ID = os.environ.get('RAZORPAY_KEY_ID', '')
RAZORPAY_KEY_SECRET = os.environ.get('RAZORPAY_KEY_SECRET', '')
razorpay_client = None
if RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET:
    razorpay_client = razorpay.Client(auth=(RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET))


# =============== MODELS ===============

class GlassItem(BaseModel):
    product_id: str
    product_name: str
    thickness: float
    width: float
    height: float
    quantity: int
    unit_price: float
    total_price: float
    edging: Optional[str] = None
    tempering: bool = False
    lamination: bool = False
    notes: Optional[str] = None


class DeliveryAddress(BaseModel):
    full_name: str
    phone: str
    address_line1: str
    address_line2: Optional[str] = None
    city: str
    state: str
    pincode: str
    landmark: Optional[str] = None


class OrderCreate(BaseModel):
    # Customer identification - can use profile_id OR manual entry
    customer_profile_id: Optional[str] = None  # If provided, auto-populate from Customer Master
    customer_name: Optional[str] = None  # Required if profile_id not provided
    customer_email: Optional[EmailStr] = None
    customer_phone: Optional[str] = None
    glass_items: List[GlassItem]
    delivery_address: Optional[DeliveryAddress] = None
    shipping_address_id: Optional[str] = None  # Use specific shipping address from profile
    delivery_type: str = "standard"
    notes: Optional[str] = None
    advance_percent: Optional[int] = None
    is_credit_customer: bool = False
    gst_number: Optional[str] = None
    company_name: Optional[str] = None
    # B2B fields from Customer Master
    place_of_supply: Optional[str] = None
    billing_address: Optional[Dict[str, Any]] = None


class RemainingPaymentVerify(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str


# =============== HELPERS ===============

async def generate_order_number() -> str:
    db = get_db()
    today = datetime.now(timezone.utc)
    prefix = f"LG{today.strftime('%y%m%d')}"
    
    count = await db.orders.count_documents({
        "order_number": {"$regex": f"^{prefix}"}
    })
    
    return f"{prefix}{str(count + 1).zfill(4)}"


async def get_advance_settings():
    db = get_db()
    settings = await db.settings.find_one({"type": "advance_settings"}, {"_id": 0})
    if not settings:
        settings = {
            "normal_customer_min": 50,
            "normal_customer_options": [50, 75, 100],
            "credit_customer_min": 0,
            "credit_customer_options": [0, 25, 50, 75, 100],
            "admin_override_allowed": True,
            "max_credit_limit": 100000
        }
    return settings


async def validate_advance_percent(total_amount: float, requested_percent: int, is_credit: bool, user_role: str):
    settings = await get_advance_settings()
    
    if is_credit:
        min_percent = settings.get("credit_customer_min", 0)
        allowed_options = settings.get("credit_customer_options", [0, 25, 50, 75, 100])
    else:
        min_percent = settings.get("normal_customer_min", 50)
        allowed_options = settings.get("normal_customer_options", [50, 75, 100])
    
    # Admin can override
    if user_role in ["admin", "super_admin", "owner"] and settings.get("admin_override_allowed", True):
        if requested_percent < 0 or requested_percent > 100:
            return False, f"Invalid advance percentage: {requested_percent}%"
        return True, None
    
    if requested_percent < min_percent:
        return False, f"Minimum advance required is {min_percent}%"
    
    if requested_percent not in allowed_options:
        return False, f"Advance must be one of: {allowed_options}%"
    
    return True, None


# =============== ENDPOINTS ===============

@orders_router.post("")
async def create_order(
    order_data: OrderCreate,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user)
):
    """Create a new order with auto-population from Customer Master"""
    db = get_db()
    
    # Variables for customer data
    customer_profile = None
    customer_name = order_data.customer_name
    customer_email = order_data.customer_email
    customer_phone = order_data.customer_phone
    company_name = order_data.company_name
    gst_number = order_data.gst_number
    billing_address = order_data.billing_address
    delivery_address = order_data.delivery_address
    is_credit_customer = order_data.is_credit_customer
    credit_limit = 0
    credit_days = 0
    place_of_supply = order_data.place_of_supply
    invoice_type = "B2C"
    
    # Auto-populate from Customer Master if profile_id provided
    if order_data.customer_profile_id:
        customer_profile = await db.customer_profiles.find_one(
            {"id": order_data.customer_profile_id, "status": "active"},
            {"_id": 0}
        )
        if not customer_profile:
            raise HTTPException(status_code=404, detail="Customer profile not found or inactive")
        
        # Auto-populate from profile
        customer_name = customer_profile.get("display_name") or order_data.customer_name
        customer_email = customer_profile.get("email") or order_data.customer_email
        customer_phone = customer_profile.get("mobile") or order_data.customer_phone
        company_name = customer_profile.get("company_name") or order_data.company_name
        gst_number = customer_profile.get("gstin") or order_data.gst_number
        billing_address = customer_profile.get("billing_address") or order_data.billing_address
        is_credit_customer = customer_profile.get("credit_type") == "credit_allowed"
        credit_limit = customer_profile.get("credit_limit", 0)
        credit_days = customer_profile.get("credit_days", 0)
        place_of_supply = customer_profile.get("place_of_supply") or order_data.place_of_supply
        invoice_type = customer_profile.get("invoice_type", "B2C")
        
        # If shipping_address_id provided, use that specific address
        if order_data.shipping_address_id and not order_data.delivery_address:
            shipping_addresses = customer_profile.get("shipping_addresses", [])
            for addr in shipping_addresses:
                if addr.get("id") == order_data.shipping_address_id:
                    delivery_address = DeliveryAddress(
                        full_name=addr.get("contact_person") or customer_name,
                        phone=addr.get("contact_phone") or customer_phone,
                        address_line1=addr.get("address_line1", ""),
                        address_line2=addr.get("address_line2"),
                        city=addr.get("city", ""),
                        state=addr.get("state", ""),
                        pincode=addr.get("pin_code", ""),
                        landmark=addr.get("site_name")
                    )
                    break
        # If no shipping address specified, use billing as delivery
        if not delivery_address and billing_address:
            delivery_address = DeliveryAddress(
                full_name=customer_name,
                phone=customer_phone,
                address_line1=billing_address.get("address_line1", ""),
                address_line2=billing_address.get("address_line2"),
                city=billing_address.get("city", ""),
                state=billing_address.get("state", ""),
                pincode=billing_address.get("pin_code", ""),
                landmark=None
            )
    
    # Validate required fields
    if not customer_name:
        raise HTTPException(status_code=400, detail="Customer name is required")
    if not customer_phone:
        raise HTTPException(status_code=400, detail="Customer phone is required")
    
    # Calculate totals
    subtotal = sum(item.total_price for item in order_data.glass_items)
    total_sqft = sum((item.width * item.height * item.quantity) / 144 for item in order_data.glass_items)
    
    # Tax calculation (18% GST)
    tax_rate = 0.18
    tax_amount = round(subtotal * tax_rate, 2)
    total_price = round(subtotal + tax_amount, 2)
    
    # Advance calculation
    advance_percent = order_data.advance_percent
    if advance_percent is None:
        # Auto-determine based on credit status
        if is_credit_customer:
            advance_percent = 0  # Credit customers can have 0% advance
        else:
            advance_percent = 50  # Normal customers default 50%
    
    is_valid, error = await validate_advance_percent(
        total_price, 
        advance_percent, 
        is_credit_customer,
        current_user.get("role", "customer")
    )
    
    if not is_valid:
        raise HTTPException(status_code=400, detail=error)
    
    # Check credit limit for credit customers
    if is_credit_customer and customer_profile:
        # Get current outstanding
        outstanding = 0
        existing_orders = await db.orders.find({
            "customer_profile_id": order_data.customer_profile_id,
            "payment_status": {"$ne": "completed"}
        }, {"remaining_amount": 1}).to_list(1000)
        
        for o in existing_orders:
            outstanding += o.get("remaining_amount", 0)
        
        if outstanding + total_price > credit_limit:
            raise HTTPException(
                status_code=400, 
                detail=f"Order exceeds credit limit. Current outstanding: ₹{outstanding:,.2f}, Limit: ₹{credit_limit:,.2f}"
            )
    
    advance_amount = round(total_price * advance_percent / 100, 2)
    remaining_amount = round(total_price - advance_amount, 2)
    
    order_id = str(uuid.uuid4())
    order_number = await generate_order_number()
    
    # Create Razorpay order for advance payment
    razorpay_order_id = None
    if advance_amount > 0 and razorpay_client:
        try:
            rz_order = razorpay_client.order.create({
                "amount": int(advance_amount * 100),
                "currency": "INR",
                "receipt": order_number,
                "notes": {
                    "order_id": order_id,
                    "type": "advance"
                }
            })
            razorpay_order_id = rz_order["id"]
        except Exception as e:
            print(f"Razorpay order creation failed: {e}")
    
    order = {
        "id": order_id,
        "order_number": order_number,
        "customer_id": current_user.get("id"),
        "customer_profile_id": order_data.customer_profile_id,  # Link to Customer Master
        "customer_name": customer_name,
        "customer_email": customer_email,
        "customer_phone": customer_phone,
        "company_name": company_name,
        "gst_number": gst_number,
        "invoice_type": invoice_type,
        "place_of_supply": place_of_supply,
        "billing_address": billing_address,
        "glass_items": [item.dict() for item in order_data.glass_items],
        "total_sqft": round(total_sqft, 2),
        "subtotal": subtotal,
        "tax_rate": tax_rate,
        "tax_amount": tax_amount,
        "total_price": total_price,
        "advance_percent": advance_percent,
        "advance_amount": advance_amount,
        "remaining_amount": remaining_amount,
        "is_credit_customer": is_credit_customer,
        "credit_limit": credit_limit,
        "credit_days": credit_days,
        "payment_status": "pending",
        "razorpay_order_id": razorpay_order_id,
        "status": "pending",
        "production_stage": None,
        "delivery_address": delivery_address.dict() if delivery_address else None,
        "delivery_type": order_data.delivery_type,
        "notes": order_data.notes,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat()
    }
    
    await db.orders.insert_one(order)
    
    # AUTO-POST TO PARTY LEDGER & GL
    # Sales Invoice → Debit Accounts Receivable, Credit Sales + GST
    await auto_post_to_ledger_orders(
        db,
        entry_type="sales_invoice",
        reference_id=order["id"],
        reference_number=order_number,
        party_type="customer",
        party_id=order_data.customer_profile_id or order.get("customer_id", ""),
        party_name=customer_name,
        amount=subtotal,
        gst_amount=tax_amount,
        description=f"Sales Order {order_number}",
        transaction_date=datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        created_by="system"
    )
    
    return {
        "message": "Order created successfully",
        "order": {k: v for k, v in order.items() if k != "_id"},
        "razorpay_order_id": razorpay_order_id,
        "razorpay_key": RAZORPAY_KEY_ID,
        "customer_profile": customer_profile  # Return profile for frontend reference
    }


@orders_router.post("/{order_id}/payment")
async def verify_payment(
    order_id: str,
    payment_data: dict,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user)
):
    """Verify Razorpay payment for order"""
    db = get_db()
    
    order = await db.orders.find_one({"id": order_id})
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    razorpay_payment_id = payment_data.get("razorpay_payment_id")
    razorpay_signature = payment_data.get("razorpay_signature")
    razorpay_order_id = payment_data.get("razorpay_order_id")
    
    # Verify signature
    if razorpay_client:
        message = f"{razorpay_order_id}|{razorpay_payment_id}"
        expected_signature = hmac.new(
            RAZORPAY_KEY_SECRET.encode(),
            message.encode(),
            hashlib.sha256
        ).hexdigest()
        
        if expected_signature != razorpay_signature:
            raise HTTPException(status_code=400, detail="Payment verification failed")
    
    # Update order
    payment_status = "partial" if order.get("remaining_amount", 0) > 0 else "completed"
    
    await db.orders.update_one(
        {"id": order_id},
        {
            "$set": {
                "razorpay_payment_id": razorpay_payment_id,
                "payment_status": payment_status,
                "status": "processing" if payment_status in ["partial", "completed"] else "pending",
                "advance_paid_at": datetime.now(timezone.utc).isoformat(),
                "updated_at": datetime.now(timezone.utc).isoformat()
            }
        }
    )
    
    # AUTO-POST TO PARTY LEDGER & GL
    # Payment Received → Debit Cash/Bank, Credit Accounts Receivable
    payment_amount = order.get("advance_amount", 0)
    await auto_post_to_ledger_orders(
        db,
        entry_type="payment_received",
        reference_id=f"{order_id}-advance",
        reference_number=f"RCP-{order.get('order_number')}-ADV",
        party_type="customer",
        party_id=order.get("user_id", ""),
        party_name=order.get("customer_name", ""),
        amount=payment_amount,
        gst_amount=0,
        description=f"Advance Payment for Order {order.get('order_number')}",
        transaction_date=datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        created_by="system"
    )
    
    return {
        "message": "Payment verified successfully",
        "order_id": order_id,
        "payment_status": payment_status
    }


@orders_router.post("/{order_id}/initiate-remaining-payment")
async def initiate_remaining_payment(
    order_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Initiate payment for remaining amount"""
    db = get_db()
    
    order = await db.orders.find_one({"id": order_id}, {"_id": 0})
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    remaining = order.get("remaining_amount", 0)
    if remaining <= 0:
        raise HTTPException(status_code=400, detail="No remaining amount to pay")
    
    # Create Razorpay order
    razorpay_order_id = None
    if razorpay_client:
        try:
            rz_order = razorpay_client.order.create({
                "amount": int(remaining * 100),
                "currency": "INR",
                "receipt": f"{order.get('order_number')}-REM",
                "notes": {
                    "order_id": order_id,
                    "type": "remaining"
                }
            })
            razorpay_order_id = rz_order["id"]
            
            await db.orders.update_one(
                {"id": order_id},
                {"$set": {"remaining_razorpay_order_id": razorpay_order_id}}
            )
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to create payment: {str(e)}")
    
    return {
        "razorpay_order_id": razorpay_order_id,
        "razorpay_key": RAZORPAY_KEY_ID,
        "amount": remaining,
        "order_number": order.get("order_number")
    }


@orders_router.post("/{order_id}/verify-remaining-payment")
async def verify_remaining_payment(
    order_id: str,
    payment_data: RemainingPaymentVerify,
    current_user: dict = Depends(get_current_user)
):
    """Verify remaining payment"""
    db = get_db()
    
    order = await db.orders.find_one({"id": order_id})
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Verify signature
    if razorpay_client:
        message = f"{payment_data.razorpay_order_id}|{payment_data.razorpay_payment_id}"
        expected_signature = hmac.new(
            RAZORPAY_KEY_SECRET.encode(),
            message.encode(),
            hashlib.sha256
        ).hexdigest()
        
        if expected_signature != payment_data.razorpay_signature:
            raise HTTPException(status_code=400, detail="Payment verification failed")
    
    # Update order
    await db.orders.update_one(
        {"id": order_id},
        {
            "$set": {
                "remaining_razorpay_payment_id": payment_data.razorpay_payment_id,
                "remaining_amount": 0,
                "payment_status": "completed",
                "remaining_paid_at": datetime.now(timezone.utc).isoformat(),
                "updated_at": datetime.now(timezone.utc).isoformat()
            }
        }
    )
    
    return {
        "message": "Remaining payment verified successfully",
        "order_id": order_id,
        "payment_status": "completed"
    }


@orders_router.post("/{order_id}/mark-cash-received")
async def mark_cash_received(
    order_id: str,
    data: dict,
    current_user: dict = Depends(get_current_user)
):
    """Mark cash payment received (admin only)"""
    if current_user.get("role") not in ["admin", "super_admin", "owner", "accountant"]:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    db = get_db()
    
    order = await db.orders.find_one({"id": order_id})
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    payment_type = data.get("payment_type", "advance")  # advance or remaining
    amount = data.get("amount", 0)
    
    update_data = {
        "updated_at": datetime.now(timezone.utc).isoformat()
    }
    
    if payment_type == "advance":
        update_data["payment_status"] = "partial" if order.get("remaining_amount", 0) > 0 else "completed"
        update_data["status"] = "processing"
        update_data["advance_paid_at"] = datetime.now(timezone.utc).isoformat()
        update_data["advance_payment_method"] = "cash"
    else:
        update_data["remaining_amount"] = 0
        update_data["payment_status"] = "completed"
        update_data["remaining_paid_at"] = datetime.now(timezone.utc).isoformat()
        update_data["remaining_payment_method"] = "cash"
    
    await db.orders.update_one({"id": order_id}, {"$set": update_data})
    
    # Record cash payment
    await db.cash_payments.insert_one({
        "id": str(uuid.uuid4()),
        "order_id": order_id,
        "order_number": order.get("order_number"),
        "amount": amount,
        "payment_type": payment_type,
        "received_by": current_user.get("name"),
        "received_at": datetime.now(timezone.utc).isoformat()
    })
    
    return {"message": "Cash payment recorded", "payment_status": update_data.get("payment_status")}


# =============== ORDER WITH 3D DESIGN ===============

class GlassConfigData(BaseModel):
    width_mm: float
    height_mm: float
    thickness_mm: float
    glass_type: str
    color_name: str
    application: Optional[str] = None
    cutouts: List[Dict[str, Any]]


class OrderWithDesignCreate(BaseModel):
    order_data: Dict[str, Any]
    glass_config: GlassConfigData


@orders_router.post("/with-design")
async def create_order_with_design(
    data: OrderWithDesignCreate,
    current_user: dict = Depends(get_current_user)
):
    """Create order and save associated 3D glass design"""
    db = get_db()
    
    # Generate unique IDs
    order_id = str(uuid.uuid4())
    glass_config_id = str(uuid.uuid4())
    
    # Save glass configuration first
    glass_config_doc = {
        "id": glass_config_id,
        "width_mm": data.glass_config.width_mm,
        "height_mm": data.glass_config.height_mm,
        "thickness_mm": data.glass_config.thickness_mm,
        "glass_type": data.glass_config.glass_type,
        "color_name": data.glass_config.color_name,
        "application": data.glass_config.application,
        "cutouts": data.glass_config.cutouts,
        "created_by": current_user.get("id"),
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat()
    }
    
    await db.glass_configs.insert_one(glass_config_doc)
    
    # Get pricing settings
    pricing_settings = await db.settings.find_one({"type": "pricing_rules"}, {"_id": 0})
    if not pricing_settings:
        pricing_settings = {
            "price_per_sqft": 300.0,
            "cutout_price": 50.0
        }
    
    # Calculate pricing
    width_ft = data.glass_config.width_mm / 304.8
    height_ft = data.glass_config.height_mm / 304.8
    area_sqft = width_ft * height_ft
    quantity = data.order_data.get("quantity", 1)
    
    price_per_sqft = float(pricing_settings.get("price_per_sqft", 300.0))
    cutout_price = float(pricing_settings.get("cutout_price", 50.0))
    
    base_price = area_sqft * price_per_sqft * quantity
    cutouts_price = len(data.glass_config.cutouts) * cutout_price * quantity
    subtotal = base_price + cutouts_price
    
    # Apply GST (18%)
    gst_amount = subtotal * 0.18
    total_amount = subtotal + gst_amount
    
    # Create order with reference to glass config
    order_number = f"ORD-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"
    
    order_doc = {
        "id": order_id,
        "order_number": order_number,
        "customer_id": current_user.get("id"),
        "customer_name": data.order_data.get("customer_name", current_user.get("name")),
        "customer_email": data.order_data.get("customer_email", current_user.get("email")),
        "customer_phone": data.order_data.get("customer_phone", ""),
        "glass_config_id": glass_config_id,  # Link to design
        "quantity": quantity,
        "notes": data.order_data.get("notes", ""),
        "status": data.order_data.get("status", "pending"),
        "payment_status": "pending",
        "product_name": f"{data.glass_config.glass_type} Glass ({data.glass_config.width_mm}x{data.glass_config.height_mm}mm)",
        # Pricing details
        "dimensions": {
            "width_mm": data.glass_config.width_mm,
            "height_mm": data.glass_config.height_mm,
            "area_sqft": round(area_sqft, 2)
        },
        "pricing": {
            "price_per_sqft": price_per_sqft,
            "cutout_price": cutout_price,
            "base_price": round(base_price, 2),
            "cutouts_price": round(cutouts_price, 2),
            "subtotal": round(subtotal, 2),
            "gst_amount": round(gst_amount, 2)
        },
        "total_amount": round(total_amount, 2),
        "advance_amount": 0,
        "remaining_amount": round(total_amount, 2),
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat()
    }
    
    await db.orders.insert_one(order_doc)
    
    # Send order confirmation email with PDF
    try:
        from math import sin, cos, pi
        import ssl
        from reportlab.lib.pagesizes import A4
        from reportlab.lib.units import mm
        from reportlab.lib import colors
        from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.graphics.shapes import Drawing, Circle, Rect, Polygon, Path, Ellipse
        
        # DIRECTLY GENERATE PDF (don't call export_pdf which needs FastAPI dependency)
        pdf_buffer = io.BytesIO()
        doc = SimpleDocTemplate(pdf_buffer, pagesize=A4, rightMargin=20*mm, leftMargin=20*mm, topMargin=20*mm, bottomMargin=20*mm)
        
        styles = getSampleStyleSheet()
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=18,
            alignment=1,
            spaceAfter=10*mm,
            textColor=colors.HexColor('#3B82F6')
        )
        
        elements = []
        elements.append(Paragraph("Glass Specification Sheet", title_style))
        elements.append(Spacer(1, 5*mm))
        
        # Glass info table
        glass_data = [
            ["Order Number", order_number],
            ["Customer", order_doc['customer_name']],
            ["Dimensions", f"{data.glass_config.width_mm} × {data.glass_config.height_mm} × {data.glass_config.thickness_mm} mm"],
            ["Glass Type", data.glass_config.glass_type],
            ["Color", data.glass_config.color_name],
            ["Quantity", str(quantity)],
        ]
        
        glass_table = Table(glass_data, colWidths=[60*mm, 100*mm])
        glass_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#3B82F6')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ]))
        elements.append(glass_table)
        elements.append(Spacer(1, 10*mm))
        
        # Draw 2D diagram with cutouts
        if data.glass_config.cutouts:
            glass_w = float(data.glass_config.width_mm)
            glass_h = float(data.glass_config.height_mm)

            # Scale drawing to fit the page while preserving proportions
            max_width = 170 * mm
            max_height = 120 * mm
            margin = 10 * mm
            scale = min((max_width - 2 * margin) / glass_w, (max_height - 2 * margin) / glass_h, 1)

            drawing_width = glass_w * scale + 2 * margin
            drawing_height = glass_h * scale + 2 * margin
            drawing = Drawing(drawing_width, drawing_height)
            offset_x = margin
            offset_y = margin
            
            # Draw glass rectangle
            drawing.add(Rect(offset_x, offset_y, glass_w * scale, glass_h * scale, fillColor=colors.HexColor('#E8F4F8'), strokeColor=colors.HexColor('#3B82F6'), strokeWidth=2))
            
            # Draw cutouts with better shape/type fallback
            cutout_colors = {
                'circle': colors.HexColor('#3B82F6'),
                'hole': colors.HexColor('#3B82F6'),
                'rectangle': colors.HexColor('#22C55E'),
                'square': colors.HexColor('#F59E0B'),
                'triangle': colors.HexColor('#F97316'),
                'diamond': colors.HexColor('#6366F1'),
                'oval': colors.HexColor('#10B981'),
                'pentagon': colors.HexColor('#8B5CF6'),
                'hexagon': colors.HexColor('#EC4899'),
                'octagon': colors.HexColor('#14B8A6'),
                'star': colors.HexColor('#F59E0B'),
                'heart': colors.HexColor('#EF4444')
            }
            
            for cutout in data.glass_config.cutouts:
                shape = (cutout.get('shape') or cutout.get('type') or 'hole').lower()
                cx = offset_x + float(cutout.get('x', 0)) * scale
                cy = offset_y + float(cutout.get('y', 0)) * scale
                cutout_color = cutout_colors.get(shape, colors.blue)

                # Fallback sizing
                diameter = float(cutout.get('diameter') or cutout.get('width') or cutout.get('height') or 20)
                width_val = float(cutout.get('width') or cutout.get('diameter') or 20)
                height_val = float(cutout.get('height') or cutout.get('diameter') or 20)
                
                if shape in ['hole', 'circle']:
                    radius = (diameter / 2) * scale
                    drawing.add(Circle(cx, cy, radius, fillColor=cutout_color, strokeColor=colors.black, strokeWidth=1))
                elif shape == 'star':
                    size = (diameter / 2) * scale
                    outer_r = size
                    inner_r = size * 0.38
                    points = []
                    for i in range(10):
                        angle = (i * pi / 5) - (pi / 2)
                        r = outer_r if i % 2 == 0 else inner_r
                        points.extend([cx + r * cos(angle), cy + r * sin(angle)])
                    drawing.add(Polygon(points, fillColor=cutout_color, strokeColor=colors.black, strokeWidth=1))
                elif shape == 'diamond':
                    size = max(width_val, height_val) * scale / 2
                    points = [
                        cx, cy + size,
                        cx + size, cy,
                        cx, cy - size,
                        cx - size, cy
                    ]
                    drawing.add(Polygon(points, fillColor=cutout_color, strokeColor=colors.black, strokeWidth=1))
                elif shape == 'heart':
                    size = diameter * scale
                    path = Path(fillColor=cutout_color, strokeColor=colors.black, strokeWidth=1)
                    scale_factor = size / 40
                    for i in range(101):
                        t = (i / 100) * 2 * pi
                        x_val = 16 * (sin(t) ** 3) * scale_factor
                        y_val = -(13 * cos(t) - 5 * cos(2*t) - 2 * cos(3*t) - cos(4*t)) * scale_factor
                        if i == 0:
                            path.moveTo(cx + x_val, cy + y_val)
                        else:
                            path.lineTo(cx + x_val, cy + y_val)
                    path.closePath()
                    drawing.add(path)
                elif shape in ['pentagon', 'hexagon', 'octagon']:
                    sides = 5 if shape == 'pentagon' else 6 if shape == 'hexagon' else 8
                    radius = (diameter / 2) * scale
                    points = []
                    for i in range(sides):
                        angle = (i * 2 * pi / sides) - (pi / 2)
                        points.extend([cx + radius * cos(angle), cy + radius * sin(angle)])
                    drawing.add(Polygon(points, fillColor=cutout_color, strokeColor=colors.black, strokeWidth=1))
                else:
                    # Rectangle/Square and other polygonal shapes fallback
                    w = width_val * scale
                    h = height_val * scale
                    drawing.add(Rect(cx - w/2, cy - h/2, w, h, fillColor=cutout_color, strokeColor=colors.black, strokeWidth=1))
            
            elements.append(drawing)
        
        # Build PDF
        doc.build(elements)
        pdf_buffer.seek(0)
        pdf_bytes = pdf_buffer.read()
        
        # Generate email HTML
        email_html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #f97316 0%, #ea580c 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                .order-details {{ background: white; padding: 20px; border-radius: 5px; margin: 20px 0; }}
                .detail-row {{ display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #eee; }}
                .total {{ font-size: 18px; font-weight: bold; color: #f97316; }}
                .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🎉 Order Confirmed!</h1>
                    <p>Thank you for your order</p>
                </div>
                <div class="content">
                    <p>Dear {order_doc['customer_name']},</p>
                    <p>Your custom glass order has been successfully placed and confirmed!</p>
                    
                    <div class="order-details">
                        <h3>Order Details</h3>
                        <div class="detail-row">
                            <span>Order Number:</span>
                            <strong>{order_number}</strong>
                        </div>
                        <div class="detail-row">
                            <span>Product:</span>
                            <span>{order_doc['product_name']}</span>
                        </div>
                        <div class="detail-row">
                            <span>Dimensions:</span>
                            <span>{data.glass_config.width_mm} × {data.glass_config.height_mm} mm</span>
                        </div>
                        <div class="detail-row">
                            <span>Thickness:</span>
                            <span>{data.glass_config.thickness_mm} mm</span>
                        </div>
                        <div class="detail-row">
                            <span>Quantity:</span>
                            <span>{quantity} pcs</span>
                        </div>
                        <div class="detail-row">
                            <span>Cutouts:</span>
                            <span>{len(data.glass_config.cutouts)} cutouts</span>
                        </div>
                        <div class="detail-row total">
                            <span>Total Amount:</span>
                            <span>₹{round(total_amount, 2):,}</span>
                        </div>
                    </div>
                    
                    <p><strong>📎 Design Specification Attached</strong></p>
                    <p>Please find the detailed design specification PDF attached with all your cutout shapes rendered accurately (heart, star, circle, etc).</p>
                    
                    <p>Our team will start processing your order soon. You'll receive updates via email and SMS.</p>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="https://lucumaaglass.in/track?order={order_id}" style="display: inline-block; padding: 15px 30px; background: #f97316; color: white; text-decoration: none; border-radius: 5px; font-weight: bold;">Track Your Order</a>
                    </div>
                    
                    <div class="footer">
                        <p>© 2026 Lucumaa Glass | Professional Glass Solutions</p>
                        <p>Contact: info@lucumaaglass.in</p>
                    </div>
                </div>
            </div>
        </body>
        </html>
        """
        
        # Send email with PDF
        SMTP_HOST = os.environ.get('SMTP_HOST', 'smtp.hostinger.com')
        SMTP_PORT = int(os.environ.get('SMTP_PORT', 465))
        SMTP_USER = os.environ.get('SMTP_USER', 'info@lucumaaglass.in')
        SENDER_EMAIL = os.environ.get('SENDER_EMAIL', SMTP_USER)
        SMTP_PASSWORD = os.environ.get('SMTP_PASSWORD') or 'Info123@@123'
        SENDER_NAME = os.environ.get('SENDER_NAME', 'Lucumaa Glass')
        recipient = order_doc.get('customer_email')
        
        if SMTP_PASSWORD and recipient:
            message = MIMEMultipart()
            message['Subject'] = f"Order Confirmed - {order_number} | Lucumaa Glass"
            message['From'] = f"{SENDER_NAME} <{SENDER_EMAIL}>"
            message['To'] = recipient
            
            html_part = MIMEText(email_html, 'html')
            message.attach(html_part)
            
            # Attach PDF
            pdf_attachment = MIMEApplication(pdf_bytes, _subtype='pdf')
            pdf_attachment.add_header('Content-Disposition', 'attachment', filename=f'order_{order_number}_specification.pdf')
            message.attach(pdf_attachment)
            
            # Create SSL context to handle certificate issues
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE
            
            # Send email
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
            logging.info(f"✅ Order confirmation email sent to {recipient}")
        else:
            logging.warning(f"⚠️ Cannot send email - SMTP missing or recipient missing (password set: {bool(SMTP_PASSWORD)}, recipient: {bool(recipient)})")
            
    except Exception as e:
        logging.error(f"❌ Error sending order email: {str(e)}")
    
    return {
        "message": "Order created successfully with 3D design",
        "order_id": order_id,
        "order_number": order_number,
        "glass_config_id": glass_config_id,
        "total_amount": round(total_amount, 2),
        "area_sqft": round(area_sqft, 2)
    }


@orders_router.get("/my-orders")
async def get_my_orders(
    include_designs: bool = False,
    current_user: dict = Depends(get_current_user)
):
    """Get orders for current user, optionally with 3D glass designs"""
    db = get_db()
    
    orders = await db.orders.find(
        {"customer_id": current_user.get("id")},
        {"_id": 0}
    ).sort("created_at", -1).to_list(100)
    
    # Populate glass configs if requested
    if include_designs:
        for order in orders:
            if order.get("glass_config_id"):
                glass_config = await db.glass_configs.find_one(
                    {"id": order["glass_config_id"]},
                    {"_id": 0}
                )
                if glass_config:
                    order["glass_config"] = glass_config
    
    return orders


@orders_router.get("/track/{order_id}")
async def track_order(order_id: str):
    """Track order status (public endpoint) - searches by ID, order_number, or job_work_number"""
    db = get_db()
    
    # Strip # if present and clean whitespace
    order_id_clean = order_id.strip().strip('#').upper()
    
    logging.info(f"Tracking request for: {order_id_clean}")
    
    # FIRST: Try regular orders with multiple search strategies
    order = await db.orders.find_one(
        {"$or": [
            {"id": order_id_clean},
            {"order_number": order_id_clean},
            {"id": {"$regex": f"^{order_id_clean}", "$options": "i"}},
            {"order_number": {"$regex": f"^{order_id_clean}", "$options": "i"}}
        ]},
        {"_id": 0, "customer_email": 0}
    )
    
    logging.info(f"Regular order found: {order is not None}")
    
    # If not found in regular orders, try job work orders
    if not order:
        logging.info(f"Searching job_work_orders collection...")
        job_work_order = await db.job_work_orders.find_one(
            {"$or": [
                {"id": order_id_clean},
                {"job_work_number": order_id_clean},
                {"id": {"$regex": f"^{order_id_clean}", "$options": "i"}},
                {"job_work_number": {"$regex": f"^{order_id_clean}", "$options": "i"}}
            ]},
            {"_id": 0}
        )
        
        logging.info(f"Job work order found: {job_work_order is not None}")
        
        if job_work_order:
            # Convert job work order format to match regular order format for tracking
            order = {
                "order_id": job_work_order.get("id"),
                "order_number": job_work_order.get("job_work_number", job_work_order.get("id")),
                "status": job_work_order.get("status", "pending"),
                "created_at": job_work_order.get("created_at"),
                "customer_name": job_work_order.get("customer_name"),
                "total_price": job_work_order.get("summary", {}).get("grand_total", 0),
                "quantity": job_work_order.get("summary", {}).get("total_pieces", 0),
                "unit": "pcs",
                "product_name": "Job Work - Glass Toughening",
                "payment_status": job_work_order.get("payment_status", "pending"),
                "order_type": "job_work"
            }
    
    if not order:
        # Log for debugging
        logging.info(f"Order not found for search term: {order_id_clean}")
        raise HTTPException(
            status_code=404, 
            detail=f"Order not found. Please check your Order ID or Order Number. Searched for: {order_id_clean}"
        )
    
    return order


@orders_router.get("/admin/all-orders")
async def admin_get_all_orders(
    include_designs: bool = False,
    skip: int = 0,
    limit: int = 100,
    status: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    """Get all orders (admin only), optionally with 3D glass designs"""
    # Check admin role
    if current_user.get("role") not in ["admin", "super_admin", "owner"]:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    db = get_db()
    
    # Build filter
    filter_query = {}
    if status:
        filter_query["status"] = status
    
    # Get orders
    orders = await db.orders.find(
        filter_query,
        {"_id": 0}
    ).sort("created_at", -1).skip(skip).limit(limit).to_list(limit)
    
    # Populate glass configs if requested
    if include_designs:
        for order in orders:
            if order.get("glass_config_id"):
                glass_config = await db.glass_configs.find_one(
                    {"id": order["glass_config_id"]},
                    {"_id": 0}
                )
                if glass_config:
                    order["glass_config"] = glass_config
    
    # Get total count
    total = await db.orders.count_documents(filter_query)
    
    return {
        "orders": orders,
        "total": total,
        "skip": skip,
        "limit": limit
    }


@orders_router.patch("/{order_id}/status")
async def update_order_status(
    order_id: str,
    data: dict,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user)
):
    """Update order status (admin only)"""
    # Check admin role
    if current_user.get("role") not in ["admin", "super_admin", "owner", "manager"]:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    db = get_db()
    
    new_status = data.get("status")
    notes = data.get("notes", "")
    
    if not new_status:
        raise HTTPException(status_code=400, detail="Status is required")
    
    # Valid statuses for regular orders
    valid_statuses = ["pending", "confirmed", "processing", "ready_for_dispatch", "dispatched", "delivered", "cancelled"]
    if new_status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of: {valid_statuses}")
    
    # Find order
    order = await db.orders.find_one({"id": order_id}, {"_id": 0})
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Update order status
    update_data = {
        "status": new_status,
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "updated_by": current_user.get("id")
    }
    
    if notes:
        update_data["status_notes"] = notes
    
    await db.orders.update_one(
        {"id": order_id},
        {"$set": update_data}
    )
    
    # Send status update email
    try:
        status_messages = {
            'pending': 'Your order is pending confirmation.',
            'confirmed': '✅ Order confirmed! Manufacturing starts soon.',
            'processing': '🏭 Your glass is being manufactured.',
            'ready_for_dispatch': '📦 Your order is ready for dispatch.',
            'dispatched': '🚚 Order dispatched! Delivery in 1-3 days.',
            'delivered': '🎉 Order delivered! Thank you for choosing us.',
            'cancelled': '❌ Your order has been cancelled.'
        }
        
        status_display = new_status.replace('_', ' ').title()
        
        email_html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #f97316 0%, #ea580c 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                .status-badge {{ display: inline-block; padding: 10px 20px; background: #10b981; color: white; border-radius: 5px; font-weight: bold; margin: 20px 0; }}
                .order-info {{ background: white; padding: 20px; border-radius: 5px; margin: 20px 0; }}
                .button {{ display: inline-block; padding: 15px 30px; background: #f97316; color: white; text-decoration: none; border-radius: 5px; font-weight: bold; margin: 20px 0; }}
                .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>📦 Order Status Update</h1>
                </div>
                <div class="content">
                    <p>Dear {order.get('customer_name', 'Customer')},</p>
                    <p>Your order status has been updated:</p>
                    
                    <div style="text-align: center;">
                        <div class="status-badge">{status_display}</div>
                        <p style="font-size: 16px; color: #666;">{status_messages.get(new_status, 'Your order status has been updated.')}</p>
                    </div>
                    
                    <div class="order-info">
                        <p><strong>Order Number:</strong> {order.get('order_number', 'N/A')}</p>
                        <p><strong>Product:</strong> {order.get('product_name', 'Custom Glass')}</p>
                        <p><strong>Updated:</strong> {datetime.now().strftime('%d %B %Y, %H:%M')}</p>
                        {f'<p><strong>Notes:</strong> {notes}</p>' if notes else ''}
                    </div>
                    
                    <div style="text-align: center;">
                        <a href="https://lucumaaglass.in/track?order={order_id}" class="button">Track Your Order</a>
                    </div>
                    
                    <p>If you have any questions, please don't hesitate to contact us.</p>
                    
                    <div class="footer">
                        <p>© 2026 Lucumaa Glass | Professional Glass Solutions</p>
                        <p>Contact: info@lucumaaglass.in</p>
                    </div>
                </div>
            </div>
        </body>
        </html>
        """
        
        async def send_status_email():
            try:
                SMTP_HOST = os.environ.get('SMTP_HOST', 'smtp.hostinger.com')
                SMTP_PORT = int(os.environ.get('SMTP_PORT', 465))
                SMTP_USER = os.environ.get('SMTP_USER', 'info@lucumaaglass.in')
                SMTP_PASSWORD = os.environ.get('SMTP_PASSWORD', '')
                
                if SMTP_PASSWORD and order.get('customer_email'):
                    message = MIMEMultipart()
                    message['Subject'] = f"Order Status Update: {status_display} - {order.get('order_number', 'Order')}"
                    message['From'] = f"Lucumaa Glass <{SMTP_USER}>"
                    message['To'] = order['customer_email']
                    
                    html_part = MIMEText(email_html, 'html')
                    message.attach(html_part)
                    
                    await aiosmtplib.send(
                        message,
                        hostname=SMTP_HOST,
                        port=SMTP_PORT,
                        use_tls=True,
                        username=SMTP_USER,
                        password=SMTP_PASSWORD
                    )
            except Exception as e:
                print(f"Failed to send status update email: {e}")
        
        # Schedule email sending
        import asyncio
        asyncio.create_task(send_status_email())
        
    except Exception as e:
        print(f"Error in status update email: {e}")
    
    return {
        "message": "Order status updated successfully",
        "order_id": order_id,
        "status": new_status
    }

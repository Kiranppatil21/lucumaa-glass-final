"""
Notifications Module - Email templates and notification triggers for ERP events
"""
import aiosmtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
import logging
from datetime import datetime

# SMTP Configuration
SMTP_HOST = os.environ.get('SMTP_HOST', 'smtp.hostinger.com')
SMTP_PORT = int(os.environ.get('SMTP_PORT', 465))
SMTP_USER = os.environ.get('SMTP_USER', '')
SMTP_PASSWORD = os.environ.get('SMTP_PASSWORD', '')
SENDER_EMAIL = os.environ.get('SENDER_EMAIL', 'info@lucumaaglass.in')
SENDER_NAME = os.environ.get('SENDER_NAME', 'Lucumaa Glass ERP')
ADMIN_EMAIL = os.environ.get('ADMIN_EMAIL', 'admin@lucumaaglass.in')


async def send_email(recipient: str, subject: str, html_content: str):
    """Send email using configured SMTP"""
    try:
        if not SMTP_PASSWORD:
            logging.warning("SMTP password not configured, skipping email")
            return False
            
        message = MIMEMultipart('alternative')
        message['Subject'] = subject
        message['From'] = f"{SENDER_NAME} <{SENDER_EMAIL}>"
        message['To'] = recipient
        
        html_part = MIMEText(html_content, 'html')
        message.attach(html_part)
        
        await aiosmtplib.send(
            message,
            hostname=SMTP_HOST,
            port=SMTP_PORT,
            username=SMTP_USER,
            password=SMTP_PASSWORD,
            use_tls=True,
        )
        logging.info(f"✅ Email sent to {recipient}: {subject}")
        return True
    except Exception as e:
        logging.error(f"❌ Email failed to {recipient}: {str(e)}")
        return False


# =============== EMAIL TEMPLATES ===============

def get_base_template(content: str, title: str = "Lucumaa Glass") -> str:
    """Base HTML email template with Lucumaa Glass branding"""
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4;">
        <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
            <!-- Header -->
            <tr>
                <td style="background: linear-gradient(135deg, #0d9488 0%, #0f766e 100%); padding: 30px; text-align: center;">
                    <h1 style="color: #ffffff; margin: 0; font-size: 28px;">Lucumaa Glass</h1>
                    <p style="color: #a7f3d0; margin: 5px 0 0 0; font-size: 14px;">Premium Glass Solutions</p>
                </td>
            </tr>
            <!-- Content -->
            <tr>
                <td style="padding: 30px;">
                    {content}
                </td>
            </tr>
            <!-- Footer -->
            <tr>
                <td style="background-color: #1e293b; padding: 20px; text-align: center;">
                    <p style="color: #94a3b8; margin: 0; font-size: 12px;">
                        © {datetime.now().year} Lucumaa Glass. All rights reserved.
                    </p>
                    <p style="color: #64748b; margin: 10px 0 0 0; font-size: 11px;">
                        Pune, Maharashtra | +91 92847 01985
                    </p>
                </td>
            </tr>
        </table>
    </body>
    </html>
    """


# =============== ORDER NOTIFICATIONS ===============

def get_new_order_email(order_data: dict) -> tuple:
    """Email template for new production order"""
    subject = f"🆕 New Production Order: {order_data.get('job_card_number', 'N/A')}"
    content = f"""
        <h2 style="color: #0d9488; margin-top: 0;">New Production Order Received</h2>
        <div style="background-color: #f0fdfa; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <table width="100%" style="font-size: 14px;">
                <tr>
                    <td style="padding: 8px 0; color: #64748b;">Job Card:</td>
                    <td style="padding: 8px 0; font-weight: bold; color: #0f172a;">{order_data.get('job_card_number', 'N/A')}</td>
                </tr>
                <tr>
                    <td style="padding: 8px 0; color: #64748b;">Glass Type:</td>
                    <td style="padding: 8px 0; color: #0f172a;">{order_data.get('glass_type', 'N/A')}</td>
                </tr>
                <tr>
                    <td style="padding: 8px 0; color: #64748b;">Size:</td>
                    <td style="padding: 8px 0; color: #0f172a;">{order_data.get('width', 0)} x {order_data.get('height', 0)} mm ({order_data.get('thickness', 0)}mm)</td>
                </tr>
                <tr>
                    <td style="padding: 8px 0; color: #64748b;">Quantity:</td>
                    <td style="padding: 8px 0; font-weight: bold; color: #0f172a;">{order_data.get('quantity', 0)} pcs</td>
                </tr>
                <tr>
                    <td style="padding: 8px 0; color: #64748b;">Priority:</td>
                    <td style="padding: 8px 0; color: #0f172a;">{'🔴 High' if order_data.get('priority', 1) >= 3 else '🟡 Normal'}</td>
                </tr>
            </table>
        </div>
        <p style="color: #64748b; font-size: 14px;">Please review and start production at your earliest convenience.</p>
        <a href="https://glassmesh.preview.emergentagent.com/erp/production" style="display: inline-block; background-color: #0d9488; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin-top: 15px;">View in ERP</a>
    """
    return subject, get_base_template(content)


# =============== PAYMENT NOTIFICATIONS ===============

def get_payment_confirmation_email(payment_data: dict, invoice_data: dict) -> tuple:
    """Email template for payment confirmation"""
    balance = invoice_data.get('total', 0) - (invoice_data.get('amount_paid', 0) + payment_data.get('amount', 0))
    status = "PAID IN FULL" if balance <= 0 else f"Balance: ₹{balance:,.2f}"
    
    subject = f"✅ Payment Received - {invoice_data.get('invoice_number', 'N/A')}"
    content = f"""
        <h2 style="color: #0d9488; margin-top: 0;">Payment Confirmation</h2>
        <p style="color: #475569;">Thank you for your payment. Here are the details:</p>
        
        <div style="background-color: #f0fdfa; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <table width="100%" style="font-size: 14px;">
                <tr>
                    <td style="padding: 8px 0; color: #64748b;">Invoice Number:</td>
                    <td style="padding: 8px 0; font-weight: bold; color: #0f172a;">{invoice_data.get('invoice_number', 'N/A')}</td>
                </tr>
                <tr>
                    <td style="padding: 8px 0; color: #64748b;">Amount Received:</td>
                    <td style="padding: 8px 0; font-weight: bold; color: #059669; font-size: 18px;">₹{payment_data.get('amount', 0):,.2f}</td>
                </tr>
                <tr>
                    <td style="padding: 8px 0; color: #64748b;">Payment Method:</td>
                    <td style="padding: 8px 0; color: #0f172a;">{payment_data.get('payment_method', 'Cash').upper()}</td>
                </tr>
                <tr>
                    <td style="padding: 8px 0; color: #64748b;">Reference:</td>
                    <td style="padding: 8px 0; color: #0f172a;">{payment_data.get('reference', '-')}</td>
                </tr>
                <tr>
                    <td style="padding: 8px 0; color: #64748b;">Status:</td>
                    <td style="padding: 8px 0; font-weight: bold; color: {'#059669' if balance <= 0 else '#d97706'};">{status}</td>
                </tr>
            </table>
        </div>
        
        <p style="color: #64748b; font-size: 14px;">If you have any questions, please don't hesitate to contact us.</p>
    """
    return subject, get_base_template(content)


# =============== INVOICE NOTIFICATIONS ===============

def get_new_invoice_email(invoice_data: dict) -> tuple:
    """Email template for new invoice"""
    subject = f"📄 Invoice {invoice_data.get('invoice_number', 'N/A')} - Lucumaa Glass"
    
    items_html = ""
    for item in invoice_data.get('items', []):
        items_html += f"""
            <tr>
                <td style="padding: 10px; border-bottom: 1px solid #e2e8f0;">{item.get('description', 'Item')}</td>
                <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: center;">{item.get('quantity', 0)}</td>
                <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: right;">₹{item.get('unit_price', 0):,.2f}</td>
                <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: right;">₹{item.get('quantity', 0) * item.get('unit_price', 0):,.2f}</td>
            </tr>
        """
    
    content = f"""
        <h2 style="color: #0d9488; margin-top: 0;">Invoice</h2>
        <div style="display: flex; justify-content: space-between; margin-bottom: 20px;">
            <div>
                <p style="color: #64748b; margin: 0;">Invoice To:</p>
                <p style="color: #0f172a; font-weight: bold; margin: 5px 0;">{invoice_data.get('customer_name', 'Customer')}</p>
                <p style="color: #64748b; margin: 0; font-size: 13px;">{invoice_data.get('customer_address', '')}</p>
                <p style="color: #64748b; margin: 0; font-size: 13px;">GST: {invoice_data.get('customer_gst', 'N/A')}</p>
            </div>
            <div style="text-align: right;">
                <p style="color: #64748b; margin: 0;">Invoice #:</p>
                <p style="color: #0f172a; font-weight: bold; margin: 5px 0;">{invoice_data.get('invoice_number', 'N/A')}</p>
                <p style="color: #64748b; margin: 0; font-size: 13px;">Date: {invoice_data.get('created_at', '')[:10]}</p>
                <p style="color: #64748b; margin: 0; font-size: 13px;">Due: {invoice_data.get('due_date', 'On Receipt')}</p>
            </div>
        </div>
        
        <table width="100%" style="border-collapse: collapse; margin: 20px 0; font-size: 14px;">
            <thead>
                <tr style="background-color: #0d9488; color: white;">
                    <th style="padding: 12px; text-align: left;">Description</th>
                    <th style="padding: 12px; text-align: center;">Qty</th>
                    <th style="padding: 12px; text-align: right;">Rate</th>
                    <th style="padding: 12px; text-align: right;">Amount</th>
                </tr>
            </thead>
            <tbody>
                {items_html}
            </tbody>
        </table>
        
        <div style="background-color: #f8fafc; padding: 15px; border-radius: 8px; margin-top: 20px;">
            <table width="100%" style="font-size: 14px;">
                <tr>
                    <td style="padding: 5px 0; color: #64748b;">Subtotal:</td>
                    <td style="padding: 5px 0; text-align: right;">₹{invoice_data.get('subtotal', 0):,.2f}</td>
                </tr>
                <tr>
                    <td style="padding: 5px 0; color: #64748b;">CGST (9%):</td>
                    <td style="padding: 5px 0; text-align: right;">₹{invoice_data.get('cgst', 0):,.2f}</td>
                </tr>
                <tr>
                    <td style="padding: 5px 0; color: #64748b;">SGST (9%):</td>
                    <td style="padding: 5px 0; text-align: right;">₹{invoice_data.get('sgst', 0):,.2f}</td>
                </tr>
                <tr style="border-top: 2px solid #0d9488;">
                    <td style="padding: 10px 0; font-weight: bold; color: #0f172a; font-size: 16px;">Total:</td>
                    <td style="padding: 10px 0; text-align: right; font-weight: bold; color: #0d9488; font-size: 18px;">₹{invoice_data.get('total', 0):,.2f}</td>
                </tr>
            </table>
        </div>
        
        <p style="color: #64748b; font-size: 13px; margin-top: 20px;">
            Please make payment to: <br>
            Bank: HDFC Bank | A/C: XXXXXXXXXX | IFSC: HDFC0001234
        </p>
    """
    return subject, get_base_template(content)


# =============== LOW STOCK ALERTS ===============

def get_low_stock_alert_email(low_stock_items: list) -> tuple:
    """Email template for low stock alert"""
    subject = f"⚠️ Low Stock Alert - {len(low_stock_items)} Items Need Attention"
    
    items_html = ""
    for item in low_stock_items:
        items_html += f"""
            <tr>
                <td style="padding: 10px; border-bottom: 1px solid #e2e8f0;">{item.get('name', 'Item')}</td>
                <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: center;">{item.get('category', 'N/A')}</td>
                <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: center; color: #dc2626; font-weight: bold;">{item.get('current_stock', 0)} {item.get('unit', 'pcs')}</td>
                <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: center;">{item.get('minimum_stock', 0)} {item.get('unit', 'pcs')}</td>
            </tr>
        """
    
    content = f"""
        <h2 style="color: #dc2626; margin-top: 0;">⚠️ Low Stock Alert</h2>
        <p style="color: #475569;">The following {len(low_stock_items)} item(s) are running low on stock and need to be reordered:</p>
        
        <table width="100%" style="border-collapse: collapse; margin: 20px 0; font-size: 14px;">
            <thead>
                <tr style="background-color: #fef2f2; color: #991b1b;">
                    <th style="padding: 12px; text-align: left;">Material</th>
                    <th style="padding: 12px; text-align: center;">Category</th>
                    <th style="padding: 12px; text-align: center;">Current Stock</th>
                    <th style="padding: 12px; text-align: center;">Min. Required</th>
                </tr>
            </thead>
            <tbody>
                {items_html}
            </tbody>
        </table>
        
        <a href="https://glassmesh.preview.emergentagent.com/erp/purchase" style="display: inline-block; background-color: #dc2626; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin-top: 15px;">Create Purchase Order</a>
    """
    return subject, get_base_template(content)


# =============== OVERDUE INVOICE REMINDER ===============

def get_overdue_invoice_email(invoice_data: dict, days_overdue: int) -> tuple:
    """Email template for overdue invoice reminder"""
    balance = invoice_data.get('total', 0) - invoice_data.get('amount_paid', 0)
    
    subject = f"⏰ Payment Reminder - Invoice {invoice_data.get('invoice_number', 'N/A')} ({days_overdue} days overdue)"
    content = f"""
        <h2 style="color: #d97706; margin-top: 0;">Payment Reminder</h2>
        <p style="color: #475569;">This is a friendly reminder that the following invoice is overdue:</p>
        
        <div style="background-color: #fffbeb; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #d97706;">
            <table width="100%" style="font-size: 14px;">
                <tr>
                    <td style="padding: 8px 0; color: #64748b;">Invoice Number:</td>
                    <td style="padding: 8px 0; font-weight: bold; color: #0f172a;">{invoice_data.get('invoice_number', 'N/A')}</td>
                </tr>
                <tr>
                    <td style="padding: 8px 0; color: #64748b;">Due Date:</td>
                    <td style="padding: 8px 0; color: #dc2626; font-weight: bold;">{invoice_data.get('due_date', 'N/A')}</td>
                </tr>
                <tr>
                    <td style="padding: 8px 0; color: #64748b;">Days Overdue:</td>
                    <td style="padding: 8px 0; color: #dc2626; font-weight: bold;">{days_overdue} days</td>
                </tr>
                <tr>
                    <td style="padding: 8px 0; color: #64748b;">Amount Due:</td>
                    <td style="padding: 8px 0; font-weight: bold; color: #dc2626; font-size: 18px;">₹{balance:,.2f}</td>
                </tr>
            </table>
        </div>
        
        <p style="color: #64748b; font-size: 14px;">Please arrange payment at your earliest convenience. If you have already made the payment, please ignore this reminder.</p>
        
        <p style="color: #64748b; font-size: 13px; margin-top: 20px;">
            Payment Details: <br>
            Bank: HDFC Bank | A/C: XXXXXXXXXX | IFSC: HDFC0001234
        </p>
    """
    return subject, get_base_template(content)


# =============== NOTIFICATION TRIGGERS ===============

async def notify_new_order(order_data: dict, admin_email: str = None):
    """Send notification for new production order"""
    email = admin_email or ADMIN_EMAIL
    if email:
        subject, html = get_new_order_email(order_data)
        await send_email(email, subject, html)


async def notify_payment_received(payment_data: dict, invoice_data: dict, customer_email: str = None):
    """Send payment confirmation to customer"""
    if customer_email:
        subject, html = get_payment_confirmation_email(payment_data, invoice_data)
        await send_email(customer_email, subject, html)


async def notify_new_invoice(invoice_data: dict, customer_email: str = None):
    """Send invoice to customer"""
    if customer_email:
        subject, html = get_new_invoice_email(invoice_data)
        await send_email(customer_email, subject, html)


async def notify_low_stock(low_stock_items: list, admin_email: str = None):
    """Send low stock alert to admin"""
    if low_stock_items:
        email = admin_email or ADMIN_EMAIL
        if email:
            subject, html = get_low_stock_alert_email(low_stock_items)
            await send_email(email, subject, html)


async def notify_overdue_invoice(invoice_data: dict, days_overdue: int, customer_email: str = None):
    """Send overdue reminder to customer"""
    if customer_email:
        subject, html = get_overdue_invoice_email(invoice_data, days_overdue)
        await send_email(customer_email, subject, html)


# =============== JOB WORK NOTIFICATIONS ===============

def get_status_badge_color(status: str) -> str:
    """Get badge color based on status"""
    colors = {
        "accepted": "#059669",
        "material_received": "#0891b2",
        "in_process": "#f59e0b",
        "completed": "#8b5cf6",
        "ready_for_delivery": "#06b6d4",
        "delivered": "#10b981",
        "cancelled": "#ef4444"
    }
    return colors.get(status, "#6b7280")


def get_status_label(status: str) -> str:
    """Get readable status label"""
    labels = {
        "accepted": "✅ Order Accepted",
        "material_received": "📦 Material Received",
        "in_process": "⚙️ In Process",
        "completed": "✔️ Completed",
        "ready_for_delivery": "🚚 Ready for Delivery",
        "delivered": "🎉 Delivered",
        "cancelled": "❌ Cancelled"
    }
    return labels.get(status, status.replace("_", " ").title())


def get_job_work_status_email(job_work_data: dict, new_status: str) -> tuple:
    """Email template for job work order status update"""
    job_work_number = job_work_data.get('job_work_number', 'N/A')
    customer_name = job_work_data.get('customer_name', 'Valued Customer')
    status_label = get_status_label(new_status)
    badge_color = get_status_badge_color(new_status)
    
    # Get glass dimensions
    glass_dims = "Not Specified"
    if job_work_data.get('items') and len(job_work_data['items']) > 0:
        item = job_work_data['items'][0]
        width = item.get('width_inch', 0)
        height = item.get('height_inch', 0)
        thickness = item.get('thickness_mm', 0)
        if width and height and thickness:
            glass_dims = f"{width}\" × {height}\" × {thickness}mm"
    
    # Status history timeline
    status_history_html = ""
    if job_work_data.get('status_history'):
        status_history_html = "<h3 style='color: #0d9488; margin-top: 20px;'>Order Timeline:</h3>"
        status_history_html += "<ul style='list-style: none; padding: 0;'>"
        for entry in job_work_data['status_history'][-5:]:  # Last 5 updates
            timestamp = entry.get('timestamp', '')
            status = entry.get('status', '')
            by = entry.get('by', 'System')
            status_label_hist = get_status_label(status)
            timestamp_formatted = timestamp.split('T')[0] if 'T' in timestamp else timestamp
            status_history_html += f"""
                <li style='padding: 8px; margin: 5px 0; background: #f0fdf4; border-left: 3px solid {get_status_badge_color(status)}; border-radius: 3px;'>
                    <strong>{status_label_hist}</strong> - {timestamp_formatted} by {by}
                </li>
            """
        status_history_html += "</ul>"
    
    content = f"""
        <h2 style="color: #0d9488; margin-top: 0;">🔔 Order Status Update</h2>
        <p style="font-size: 16px; color: #1e293b;">Hi {customer_name},</p>
        
        <p style="font-size: 14px; color: #475569;">Your job work order status has been updated:</p>
        
        <!-- Status Badge -->
        <div style="background-color: {badge_color}; color: white; padding: 15px; border-radius: 8px; text-align: center; margin: 20px 0;">
            <h3 style="margin: 0; font-size: 20px;">{status_label}</h3>
        </div>
        
        <!-- Order Details -->
        <table width="100%" cellpadding="0" cellspacing="0" style="margin: 20px 0; border-collapse: collapse;">
            <tr style="background-color: #f8fafc;">
                <td style="padding: 12px; border: 1px solid #e2e8f0; font-weight: bold; color: #0d9488;">Job Work Number</td>
                <td style="padding: 12px; border: 1px solid #e2e8f0; color: #1e293b;">{job_work_number}</td>
            </tr>
            <tr>
                <td style="padding: 12px; border: 1px solid #e2e8f0; font-weight: bold; color: #0d9488;">Glass Dimensions</td>
                <td style="padding: 12px; border: 1px solid #e2e8f0; color: #1e293b;">{glass_dims}</td>
            </tr>
            <tr style="background-color: #f8fafc;">
                <td style="padding: 12px; border: 1px solid #e2e8f0; font-weight: bold; color: #0d9488;">Current Status</td>
                <td style="padding: 12px; border: 1px solid #e2e8f0; color: #1e293b;">{status_label}</td>
            </tr>
            <tr>
                <td style="padding: 12px; border: 1px solid #e2e8f0; font-weight: bold; color: #0d9488;">Updated On</td>
                <td style="padding: 12px; border: 1px solid #e2e8f0; color: #1e293b;">{datetime.now().strftime('%d %b %Y, %H:%M:%S')}</td>
            </tr>
        </table>
        
        {status_history_html}
        
        <!-- Call to Action -->
        <div style="background-color: #f0fdf4; border-left: 4px solid #0d9488; padding: 15px; margin: 20px 0; border-radius: 4px;">
            <p style="margin: 0; color: #166534; font-size: 14px;">
                Need help or want to track your order? Contact us at <strong>+91 92847 01985</strong> or reply to this email.
            </p>
        </div>
        
        <p style="font-size: 13px; color: #64748b; margin-top: 20px;">Thank you for choosing Lucumaa Glass!</p>
    """
    
    subject = f"📦 Job Work Status Updated: {status_label} - {job_work_number}"
    return subject, get_base_template(content)


def get_job_work_completion_email(job_work_data: dict) -> tuple:
    """Email template for job work order completion notification"""
    job_work_number = job_work_data.get('job_work_number', 'N/A')
    customer_name = job_work_data.get('customer_name', 'Valued Customer')
    
    content = f"""
        <h2 style="color: #0d9488; margin-top: 0;">✅ Your Job Work Order is Complete!</h2>
        <p style="font-size: 16px; color: #1e293b;">Hi {customer_name},</p>
        
        <p style="font-size: 14px; color: #475569;">Great news! Your job work order has been completed successfully:</p>
        
        <!-- Completion Badge -->
        <div style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; padding: 15px; border-radius: 8px; text-align: center; margin: 20px 0;">
            <h3 style="margin: 0; font-size: 20px;">✔️ Order Completed</h3>
        </div>
        
        <!-- Order Details -->
        <table width="100%" cellpadding="0" cellspacing="0" style="margin: 20px 0; border-collapse: collapse;">
            <tr style="background-color: #f8fafc;">
                <td style="padding: 12px; border: 1px solid #e2e8f0; font-weight: bold; color: #0d9488;">Job Work Number</td>
                <td style="padding: 12px; border: 1px solid #e2e8f0; color: #1e293b;">{job_work_number}</td>
            </tr>
            <tr>
                <td style="padding: 12px; border: 1px solid #e2e8f0; font-weight: bold; color: #0d9488;">Completion Date</td>
                <td style="padding: 12px; border: 1px solid #e2e8f0; color: #1e293b;">{datetime.now().strftime('%d %b %Y')}</td>
            </tr>
        </table>
        
        <!-- Next Steps -->
        <div style="background-color: #fef3c7; border-left: 4px solid #f59e0b; padding: 15px; margin: 20px 0; border-radius: 4px;">
            <h4 style="margin: 0 0 8px 0; color: #92400e;">What's Next?</h4>
            <ul style="margin: 0; padding-left: 20px; color: #78350f; font-size: 14px;">
                <li>Your order is ready for pickup/delivery</li>
                <li>Please arrange pickup at your earliest convenience</li>
                <li>Contact us for delivery options</li>
            </ul>
        </div>
        
        <!-- Contact -->
        <div style="background-color: #f0fdf4; border-left: 4px solid #0d9488; padding: 15px; margin: 20px 0; border-radius: 4px;">
            <p style="margin: 0; color: #166534; font-size: 14px;">
                For pickup/delivery coordination: <strong>+91 92847 01985</strong>
            </p>
        </div>
    """
    
    subject = f"✅ Your Job Work Order is Complete - {job_work_number}"
    return subject, get_base_template(content)


async def notify_job_work_status_change(job_work_data: dict, customer_email: str):
    """Send email notification when job work order status changes"""
    if customer_email:
        status = job_work_data.get('status', 'unknown')
        subject, html = get_job_work_status_email(job_work_data, status)
        await send_email(customer_email, subject, html)
        logging.info(f"Job work status notification sent to {customer_email}")


async def notify_job_work_completed(job_work_data: dict, customer_email: str):
    """Send completion notification for job work order"""
    if customer_email:
        subject, html = get_job_work_completion_email(job_work_data)
        await send_email(customer_email, subject, html)
        logging.info(f"Job work completion notification sent to {customer_email}")


# =============== ORDER NOTIFICATIONS (Additional) ===============

def get_order_status_email(order_data: dict, new_status: str) -> tuple:
    """Email template for production order status update"""
    order_number = order_data.get('order_number', 'N/A')
    customer_name = order_data.get('customer_name', 'Valued Customer')
    
    # Map status to labels
    status_labels = {
        "pending": "⏳ Pending",
        "processing": "⚙️ Processing",
        "production": "🔨 In Production",
        "quality_check": "✅ Quality Check",
        "packing": "📦 Packing",
        "ready": "🚚 Ready for Dispatch",
        "dispatched": "📮 Dispatched",
        "delivered": "🎉 Delivered",
        "cancelled": "❌ Cancelled"
    }
    
    status_label = status_labels.get(new_status, new_status.replace("_", " ").title())
    
    status_colors = {
        "pending": "#6b7280",
        "processing": "#3b82f6",
        "production": "#f59e0b",
        "quality_check": "#8b5cf6",
        "packing": "#06b6d4",
        "ready": "#10b981",
        "dispatched": "#0d9488",
        "delivered": "#059669",
        "cancelled": "#ef4444"
    }
    badge_color = status_colors.get(new_status, "#6b7280")
    
    # Get order items summary
    items_html = "<h4 style='color: #0d9488;'>Order Items:</h4>"
    total_items = 0
    if order_data.get('items'):
        items_html += "<ul style='margin: 10px 0; padding-left: 20px; font-size: 14px;'>"
        for item in order_data['items'][:5]:  # Show first 5 items
            quantity = item.get('quantity', 1)
            total_items += quantity
            item_name = item.get('product_name', 'Product')
            items_html += f"<li>{item_name} - Qty: {quantity}</li>"
        if len(order_data['items']) > 5:
            items_html += f"<li><em>+ {len(order_data['items']) - 5} more items</em></li>"
        items_html += "</ul>"
    else:
        items_html += "<p style='font-size: 14px;'>Order details available on your account</p>"
    
    content = f"""
        <h2 style="color: #0d9488; margin-top: 0;">📦 Your Order Status Updated</h2>
        <p style="font-size: 16px; color: #1e293b;">Hi {customer_name},</p>
        
        <p style="font-size: 14px; color: #475569;">Your order status has been updated:</p>
        
        <!-- Status Badge -->
        <div style="background-color: {badge_color}; color: white; padding: 15px; border-radius: 8px; text-align: center; margin: 20px 0;">
            <h3 style="margin: 0; font-size: 20px;">{status_label}</h3>
        </div>
        
        <!-- Order Details -->
        <table width="100%" cellpadding="0" cellspacing="0" style="margin: 20px 0; border-collapse: collapse;">
            <tr style="background-color: #f8fafc;">
                <td style="padding: 12px; border: 1px solid #e2e8f0; font-weight: bold; color: #0d9488;">Order Number</td>
                <td style="padding: 12px; border: 1px solid #e2e8f0; color: #1e293b;">{order_number}</td>
            </tr>
            <tr>
                <td style="padding: 12px; border: 1px solid #e2e8f0; font-weight: bold; color: #0d9488;">Status</td>
                <td style="padding: 12px; border: 1px solid #e2e8f0; color: #1e293b;">{status_label}</td>
            </tr>
            <tr style="background-color: #f8fafc;">
                <td style="padding: 12px; border: 1px solid #e2e8f0; font-weight: bold; color: #0d9488;">Updated On</td>
                <td style="padding: 12px; border: 1px solid #e2e8f0; color: #1e293b;">{datetime.now().strftime('%d %b %Y, %H:%M:%S')}</td>
            </tr>
        </table>
        
        <!-- Items Summary -->
        {items_html}
        
        <!-- Status Info -->
        <div style="background-color: #f0fdf4; border-left: 4px solid #0d9488; padding: 15px; margin: 20px 0; border-radius: 4px;">
            <p style="margin: 0; color: #166534; font-size: 14px;">
                Your order is progressing smoothly. You can track the latest updates on your account dashboard or contact us for assistance.
            </p>
        </div>
        
        <!-- Contact -->
        <div style="background-color: #fef3c7; border-left: 4px solid #f59e0b; padding: 15px; margin: 20px 0; border-radius: 4px;">
            <p style="margin: 0; color: #78350f; font-size: 14px;">
                For order tracking or support: <strong>+91 92847 01985</strong>
            </p>
        </div>
        
        <p style="font-size: 13px; color: #64748b; margin-top: 20px;">Thank you for your business with Lucumaa Glass!</p>
    """
    
    subject = f"📦 Order Status Updated: {status_label} - {order_number}"
    return subject, get_base_template(content)


async def notify_order_status_change(order_data: dict, customer_email: str):
    """Send email notification when order status changes"""
    if customer_email:
        status = order_data.get('status', 'processing')
        subject, html = get_order_status_email(order_data, status)
        await send_email(customer_email, subject, html)
        logging.info(f"Order status notification sent to {customer_email}")

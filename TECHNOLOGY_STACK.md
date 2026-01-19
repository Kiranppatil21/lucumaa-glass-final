# Glass ERP - Complete Technology Stack Documentation

## 🎯 Application Overview
**Glass ERP** - Full-stack Enterprise Resource Planning system for glass manufacturing
- Custom glass ordering and 3D design
- Job work management  
- Inventory, accounting, customer management
- Production tracking and reporting

---

## 📚 **COMPLETE TECHNOLOGY STACK**

### **🔴 Backend Technologies**

#### **Core Framework & Runtime**
- **Python 3.11+** - Primary programming language
- **FastAPI 0.110.1** - Modern async web framework
  - High performance (based on Starlette)
  - Automatic API documentation (Swagger/OpenAPI)
  - Type hints and validation
  - Async/await support
- **Uvicorn 0.25.0** - ASGI server
  - Lightning-fast async server
  - Hot reload in development
  - Production-grade performance

#### **Database**
- **MongoDB 4.5+** - NoSQL document database
  - Flexible schema for complex data
  - High performance for reads/writes
  - Horizontal scaling capability
- **Motor 3.3.1** - Async MongoDB driver
  - Native async/await support
  - Connection pooling
  - GridFS for file storage

#### **Authentication & Security**
- **bcrypt 4.1.3** - Password hashing
  - Secure password storage
  - Salt generation
- **PyJWT 2.10.1** - JSON Web Token
  - Stateless authentication
  - Token-based auth system
- **python-jose 3.5.0** - JOSE implementation
  - JWT signing and verification
  - Encryption support
- **passlib 1.7.4** - Password hashing library
  - Multiple hashing algorithms
  - Password strength validation

#### **Payment Integration**
- **Razorpay 2.0.0** - Payment gateway
  - UPI, cards, net banking
  - Subscription management
  - Refunds and webhooks

#### **Communication**
- **aiosmtplib 5.0.0** - Async SMTP client
  - Email sending (transactional)
  - Template-based emails
- **Twilio 9.9.0** - SMS/WhatsApp API
  - OTP sending
  - Notifications
  - WhatsApp Business integration
- **Resend 2.19.0** - Modern email API
  - Transactional emails
  - Email analytics

#### **File Processing & Generation**
- **ReportLab 4.4.7** - PDF generation
  - Invoices, quotations
  - Specification sheets
  - Production reports
- **Pillow 12.0.0** - Image processing
  - Image manipulation
  - Thumbnail generation
  - Format conversion
- **python-barcode 0.16.1** - Barcode generation
  - Product barcodes
  - Order tracking
- **qrcode 8.2** - QR code generation
  - Share configurations
  - Product tracking
- **openpyxl 3.1.5** - Excel file handling
  - Import/export data
  - Reports in Excel format
- **xlsxwriter 3.2.9** - Excel file writing
  - Advanced Excel features
  - Charts and formatting
- **PyPDF2 3.0.1** - PDF manipulation
  - Merge/split PDFs
  - Extract text

#### **Data Processing**
- **Pandas 2.3.3** - Data analysis
  - Report generation
  - Data transformation
  - CSV/Excel processing
- **NumPy 2.4.0** - Numerical computing
  - Array operations
  - Mathematical calculations

#### **Geolocation & Mapping**
- **geopy 2.4.1** - Geocoding library
  - Address to coordinates
  - Distance calculations
- **haversine 2.9.0** - Distance calculation
  - GPS coordinate distance
  - Transport cost calculation

#### **Cloud Storage**
- **boto3 1.42.16** - AWS SDK
  - S3 file storage
  - Cloud backups
- **botocore 1.42.16** - AWS core library
- **s3transfer 0.16.0** - S3 transfer manager
- **s5cmd 0.2.0** - Fast S3 operations

#### **Scheduling & Background Tasks**
- **APScheduler 3.11.0** - Task scheduler
  - Automated reports
  - Cleanup tasks
  - Periodic data sync

#### **HTTP & API Clients**
- **aiohttp 3.13.2** - Async HTTP client
  - External API calls
  - Webhook handling
- **aiohttp-retry 2.9.1** - Retry mechanism
  - Automatic retry on failures
- **requests 2.32.5** - HTTP library
  - Simple API calls
  - OAuth integration
- **requests-oauthlib 2.0.0** - OAuth support

#### **Validation & Type Safety**
- **Pydantic 2.12.5** - Data validation
  - Type checking
  - Data serialization
  - API request/response validation
- **pydantic_core 2.41.5** - Pydantic core engine
- **email-validator 2.3.0** - Email validation

#### **Development Tools**
- **python-dotenv 1.2.1** - Environment variables
  - Configuration management
  - Secrets handling
- **black 25.12.0** - Code formatter
  - Consistent code style
- **flake8 7.3.0** - Code linter
  - Code quality checks
  - PEP 8 compliance
- **isort 7.0.0** - Import sorter
  - Organized imports
- **mypy 1.19.1** - Static type checker
  - Type hint validation
- **pytest 9.0.2** - Testing framework
  - Unit tests
  - Integration tests

#### **Utilities**
- **python-multipart 0.0.21** - File upload handling
- **python-dateutil 2.9.0** - Date manipulation
- **pytz 2025.2** - Timezone handling
- **tzdata 2025.3** - Timezone database
- **tzlocal 5.3.1** - Local timezone detection
- **rich 14.2.0** - Terminal formatting
  - Colored output
  - Progress bars
- **markdown-it-py 4.0.0** - Markdown parsing
- **watchfiles 1.1.1** - File watching
  - Hot reload support

---

### **🔵 Frontend Technologies**

#### **Core Framework**
- **React 19.0.0** - UI library
  - Latest React features
  - Concurrent rendering
  - Server components ready
- **React DOM 19.0.0** - React renderer
- **React Scripts 5.0.1** - Build tooling
  - Webpack configuration
  - Development server
  - Production builds

#### **Routing & Navigation**
- **React Router DOM 7.5.1** - Client-side routing
  - Single Page Application
  - Dynamic routing
  - Protected routes

#### **3D Graphics Engine** ⭐ **KEY FEATURE**
- **Babylon.js 8.44.0** - 3D rendering
  - @babylonjs/core - Core engine
  - @babylonjs/gui - 2D UI overlays
  - @babylonjs/loaders - Model loading
- **earcut 3.0.2** - Polygon triangulation
  - Custom shape rendering
  - Complex cutout shapes

#### **UI Component Libraries**
- **Radix UI** - Headless component primitives (26 components)
  - @radix-ui/react-accordion
  - @radix-ui/react-alert-dialog
  - @radix-ui/react-avatar
  - @radix-ui/react-checkbox
  - @radix-ui/react-dialog
  - @radix-ui/react-dropdown-menu
  - @radix-ui/react-popover
  - @radix-ui/react-select
  - @radix-ui/react-slider
  - @radix-ui/react-switch
  - @radix-ui/react-tabs
  - @radix-ui/react-toast
  - @radix-ui/react-tooltip
  - And 13 more...
  - Accessible by default (ARIA compliant)
  - Fully customizable styling
  - Keyboard navigation

#### **Styling**
- **Tailwind CSS** - Utility-first CSS
  - Rapid UI development
  - Responsive design
  - Custom design system
- **PostCSS 8.4.49** - CSS processor
- **Autoprefixer 10.4.20** - Browser compatibility
- **tailwind-merge 3.2.0** - Class name merging
- **tailwindcss-animate 1.0.7** - Animation utilities
- **class-variance-authority 0.7.1** - Component variants
- **clsx 2.1.1** - Conditional classes

#### **Forms & Validation**
- **React Hook Form 7.56.2** - Form management
  - Performance optimized
  - Validation built-in
  - TypeScript support
- **Zod 3.24.4** - Schema validation
  - Type-safe validation
  - Error handling
- **@hookform/resolvers 5.0.1** - Form resolvers
- **input-otp 1.4.2** - OTP input component

#### **State Management & Data Fetching**
- **Axios 1.8.4** - HTTP client
  - API requests
  - Interceptors
  - Request/response transformation
- **React Context API** - Built-in (in use)
  - Global state
  - Authentication state

#### **Charts & Visualizations**
- **Recharts 3.6.0** - Chart library
  - Line, bar, pie charts
  - Dashboard analytics
  - Responsive charts

#### **Maps**
- **Leaflet 1.9.4** - Map library
  - Interactive maps
  - Location tracking
  - Delivery route planning
- **React Leaflet 5.0.0** - React bindings

#### **Animations**
- **Framer Motion 12.23.26** - Animation library
  - Page transitions
  - Component animations
  - Gesture detection

#### **Utilities**
- **date-fns 4.1.0** - Date manipulation
  - Date formatting
  - Time calculations
- **qrcode.react 4.2.0** - QR code generation
  - Share configurations
  - Order tracking
- **html2canvas 1.4.1** - Screenshot generation
  - Export designs as images
- **react-markdown 10.1.0** - Markdown rendering
- **cmdk 1.1.1** - Command palette
  - Keyboard shortcuts

#### **Payment Integration**
- **react-razorpay 3.0.1** - Razorpay React SDK
  - Payment button
  - Checkout integration

#### **UI Enhancements**
- **sonner 2.0.3** - Toast notifications
  - Non-intrusive alerts
  - Beautiful animations
- **vaul 1.1.2** - Drawer component
  - Mobile-friendly
- **next-themes 0.4.6** - Theme management
  - Dark/light mode
  - System preference detection
- **embla-carousel-react 8.6.0** - Carousel
  - Touch-enabled
  - Auto-play support
- **react-resizable-panels 3.0.1** - Resizable panels
  - Split views
  - Adjustable layouts

#### **SEO & Meta**
- **react-helmet-async 2.0.5** - Head management
  - Dynamic meta tags
  - SEO optimization

#### **Build Tools**
- **@craco/craco 7.1.0** - Create React App Config Override
  - Custom webpack config
  - Path aliases
  - Plugin support

#### **Code Quality**
- **ESLint 9.23.0** - Code linter
  - eslint-plugin-react 7.37.4
  - eslint-plugin-react-hooks 5.2.0
  - eslint-plugin-jsx-a11y 6.10.2 (Accessibility)
  - eslint-plugin-import 2.31.0
- **@babel/plugin-proposal-private-property-in-object** - Babel plugin

---

### **🗄️ Database Architecture**

#### **MongoDB Collections**
- **users** - User accounts and authentication
- **customers** - Customer master data
- **orders** - Order management
- **products** - Product catalog
- **inventory** - Stock tracking
- **job_work** - Job work orders
- **glass_configs** - 3D configurations
- **invoices** - Billing data
- **expenses** - Expense tracking
- **attendance** - Employee attendance
- **holidays** - Holiday calendar
- **assets** - Asset management
- **daily_reports** - Production reports
- **gst_records** - GST/tax data

#### **Database Features Used**
- Document relationships (references)
- Indexes for performance
- Aggregation pipelines
- Text search
- GridFS for file storage
- Change streams (real-time updates)

---

### **🔧 Development Environment**

#### **Package Managers**
- **npm** - Frontend dependency management
- **pip** - Python package management

#### **Version Control**
- **Git** - Source control
- **.gitignore** - Ignore patterns

#### **Environment Management**
- **.env files** - Configuration
  - Development (.env)
  - Production (.env.production)
- **python-dotenv** - Load environment variables

#### **Development Servers**
- **Uvicorn** - Backend server (with hot reload)
- **React Dev Server** - Frontend server (with hot reload)

---

### **☁️ Deployment & DevOps**

#### **Recommended Hosting Options**
1. **VPS Hosting** (Hostinger, DigitalOcean)
   - Nginx - Reverse proxy
   - Supervisor - Process management
   - Let's Encrypt - SSL certificates

2. **Cloud Platforms** (Railway, Render)
   - Auto-deploy from Git
   - Managed databases
   - Auto-scaling

#### **Production Tools**
- **Nginx** - Web server & reverse proxy
- **Supervisor** - Process manager (keeps backend running)
- **systemd** - Service management
- **Let's Encrypt** - Free SSL certificates
- **MongoDB Atlas** - Managed MongoDB (optional)

#### **Build Process**
- **Frontend:** `npm run build` → Static files
- **Backend:** Python dependencies via pip
- **Assets:** Optimization & minification

---

### **📡 External APIs & Integrations**

#### **Payment Gateway**
- **Razorpay** - Payment processing
  - UPI, Cards, Net Banking
  - Webhooks for payment status

#### **Communication**
- **SMTP (Hostinger)** - Email delivery
- **Twilio** - SMS & WhatsApp
- **Resend** - Modern email API

#### **Cloud Services**
- **AWS S3** - File storage (optional)
- **MongoDB Atlas** - Database hosting (optional)

---

### **🔐 Security Features**

#### **Authentication**
- JWT tokens (stateless)
- bcrypt password hashing
- Role-based access control (RBAC)
  - Super Admin
  - Admin
  - Staff
  - Customer

#### **Data Protection**
- CORS configuration
- HTTPS/SSL encryption
- Input validation (Pydantic)
- SQL injection prevention (NoSQL)
- XSS protection (React)
- CSRF protection

#### **API Security**
- Bearer token authentication
- Request rate limiting
- Input sanitization
- Error handling (no data leaks)

---

### **📊 Key Features by Technology**

#### **3D Glass Design Tool**
- **Babylon.js** - 3D rendering engine
- **Canvas API** - 2D drawing
- **earcut** - Polygon triangulation
- Real-time visualization
- Drag-and-drop editing
- Custom shape creation
- Export to PDF

#### **Order Management**
- FastAPI endpoints
- MongoDB storage
- PDF invoice generation (ReportLab)
- QR code tracking
- Email notifications

#### **Customer Portal**
- React components
- Protected routes
- Order tracking
- Profile management
- Rewards system

#### **Inventory System**
- Stock tracking
- Low stock alerts
- Product catalog
- Purchase orders

#### **Accounting Module**
- GST calculation
- Invoice generation
- Expense tracking
- Financial reports
- Excel export

#### **Job Work Management**
- 3D configurator
- Labour rate calculation
- Transport cost estimation
- Job work tracking

---

### **📈 Performance Optimizations**

#### **Frontend**
- Code splitting
- Lazy loading
- Image optimization
- Bundle size optimization
- Memoization (React.memo)
- Virtual scrolling

#### **Backend**
- Async/await (non-blocking)
- Database indexing
- Connection pooling
- Caching strategies
- Query optimization

---

### **🧪 Testing (Setup Available)**

#### **Backend Testing**
- **pytest** - Test framework
- Unit tests
- Integration tests
- API endpoint testing

#### **Frontend Testing**
- **React Testing Library** (via react-scripts)
- Component testing
- Integration testing

---

### **📦 Build Output**

#### **Frontend Production Build**
- **Size:** ~9.3MB (optimized)
- **Format:** Static HTML/CSS/JS
- **Hosting:** Any web server (Nginx, Apache, CDN)

#### **Backend Deployment**
- **Format:** Python application
- **Runtime:** Python 3.11+
- **Requirements:** requirements.txt

---

## 🎯 **Technology Stack Summary**

### **Why These Technologies?**

1. **FastAPI + React** 
   - Modern, fast, scalable
   - Type-safe
   - Great developer experience

2. **MongoDB**
   - Flexible schema for complex data
   - Fast queries
   - Easy to scale

3. **Babylon.js**
   - Professional 3D rendering
   - CAD-like functionality
   - Production-ready exports

4. **Tailwind CSS + Radix UI**
   - Rapid development
   - Consistent design
   - Accessibility built-in

5. **Razorpay**
   - India-focused
   - All payment methods
   - Easy integration

---

## 🔄 **Data Flow Architecture**

```
User Browser (React)
    ↓ HTTP/HTTPS
Nginx (Reverse Proxy)
    ↓
FastAPI Backend (Python/Uvicorn)
    ↓
MongoDB (Database)
    ↓
External APIs (Razorpay, Twilio, AWS)
```

---

## 📁 **Project Structure**

```
Glass/
├── frontend/          # React application
│   ├── src/
│   │   ├── components/   # Reusable components
│   │   ├── pages/        # Route pages
│   │   ├── contexts/     # React contexts
│   │   ├── utils/        # Utilities
│   │   └── App.js        # Main app
│   ├── public/           # Static assets
│   └── package.json      # Dependencies
│
├── backend/           # FastAPI application
│   ├── server.py         # Main server
│   ├── routers/          # API routes
│   ├── models/           # Data models
│   ├── utils/            # Utilities
│   └── requirements.txt  # Dependencies
│
├── tests/             # Test files
├── memory/            # Documentation
└── glass-erp-deployment/ # Production build
```

---

## 💰 **Hosting Requirements**

### **Minimum Requirements**
- **CPU:** 1 core
- **RAM:** 2GB (4GB recommended)
- **Storage:** 10GB SSD
- **Bandwidth:** 1TB/month
- **OS:** Ubuntu 20.04+ / Linux

### **Software Requirements**
- Python 3.11+
- MongoDB 4.5+
- Node.js 18+ (for building)
- Nginx (production)

### **Why VPS/Cloud Required?**
- Need to run Python processes 24/7
- Need MongoDB daemon running
- Need process management (Supervisor)
- Shared hosting = PHP only ❌

---

## 🚀 **Getting Started**

### **Local Development**
```bash
# Backend
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn server:app --reload

# Frontend
cd frontend
npm install --legacy-peer-deps
npm start
```

### **Production Deployment**
See: 
- HOSTINGER_DEPLOYMENT.md (VPS)
- DEPLOYMENT_RAILWAY.md (Cloud)
- DEPLOYMENT_COMPARISON.md (Options)

---

## 📝 **License & Credits**

**Developed for:** Lucumaa Glass (Lucumaa Corporation Pvt. Ltd.)  
**Technology Stack:** MERN-like (MongoDB, Express→FastAPI, React, Node.js)  
**Architecture:** Full-stack monorepo  
**Year:** 2025-2026

---

This is a **production-grade, enterprise ERP system** with modern technologies and best practices throughout the stack!

# DevOps Learning Platform

A comprehensive developer-focused learning platform for DevOps engineering, container orchestration, CI/CD automation, and cloud infrastructure.

---

## 🎨 Design System & UI/UX (UI UX Pro Max + 21st.dev)

The platform interface has been redesigned following the **UI UX Pro Max** design intelligence guidelines and modern **21st.dev** component patterns.

### Brand Palette (Strict Two-Color System)

- **Primary Brand Accent — Indigo (`#4F46E5`)**:
  Used for primary buttons, main interactive actions, active navigation tabs, links, and key focus rings.
- **Secondary Brand Accent — Teal (`#0D9488`)**:
  Used for verified status badges, progress indicators, course completion tracks, and supporting highlights.
- **Surface & Neutrals**: Dark developer theme (`#090D16` app background, `#0F172A` elevated cards, `#1E293B` borders, `#F8FAFC` high-contrast typography).

### 21st.dev Components Integrated

1. **6-Digit OTP / PIN Input** (`web/src/components/OtpInput.jsx`):
   - Individual box slots with active Indigo focus rings and Teal filled highlights.
   - Automatic focus advancement on single-digit entry, backspace backward step, and arrow-key navigation.
   - Full clipboard paste parsing with automatic slot distribution.
2. **Developer Background Grid** (`web/src/components/BackgroundGrid.jsx`):
   - Subtle developer grid with radial ambient Indigo and Teal glow overlays.
3. **Glassmorphic Spotlight Card** (`web/src/components/Card.jsx`):
   - Frosted glass depth (`backdrop-filter: blur(16px)`), subtle borders, and smooth elevation on hover.
4. **Pill Badges & Live Status Dots** (`web/src/components/Badge.jsx`):
   - Compact badges for verified accounts, learning tracks, and live session pulse indicators.
5. **Interactive Glow Buttons** (`web/src/components/Button.jsx`):
   - Primary (Indigo), Secondary (Teal), Outline, and Ghost variants with accessible focus rings and built-in loading spinners.
6. **Segmented Curriculum Tabs** (`web/src/components/Tabs.jsx`):
   - Interactive track switcher for Kubernetes, CI/CD, Docker, and Terraform modules.
7. **Gradient Progress Indicators** (`web/src/components/ProgressBar.jsx`):
   - Accessible progress bar with Teal-to-Indigo gradient track and real-time completion percentages.

---

## 🔐 Authentication & Email OTP Verification Architecture

The application enforces secure authentication through **JWT**, **bcryptjs** password hashing, **Google OAuth 2.0**, and **mandatory email OTP verification** for local accounts.

### Email/Password Registration Flow

```
User Enters Credentials 
       │
       ▼
Input Validation & Duplicate Check
       │
       ▼
Generate CSPRNG 6-Digit OTP & SHA-256 Hash
       │
       ▼
Dispatch OTP via SMTP (Nodemailer) ──► (Fail: 500 error, retryable)
       │
       ▼ (Success)
Save User (isEmailVerified: false) & OtpVerification Record
       │
       ▼
Redirect to /verify-email (NO JWT Issued)
       │
       ▼
User Enters 6-Digit Code
       │
       ▼
Constant-Time Hash Comparison (timingSafeEqual)
- Max 5 incorrect attempts (lockout on 5th)
- 10-minute expiry check
- Single-use atomic update (isConsumed: true)
       │
       ▼ (Success)
User marked isEmailVerified: true ──► Signed JWT Issued ──► Redirect to /dashboard
```

### OTP Security Defenses

- **Six Numeric Digits**: Generated via Node.js cryptographic CSPRNG (`crypto.randomInt`).
- **Zero Plaintext Storage**: Only salted SHA-256 hashes are persisted in the database.
- **Timing Attack Resistance**: Evaluated using `crypto.timingSafeEqual`.
- **Automatic TTL Expiry**: OTP documents expire after 10 minutes and are purged by MongoDB's TTL index.
- **Single-Use Guarantee**: Atomic MongoDB `findOneAndUpdate({ isConsumed: false }, { isConsumed: true })` prevents race condition reuse.
- **Brute-Force Lockout**: Codes are permanently invalidated after 5 failed attempts.
- **Cooldown Throttling**: Server enforces a strict minimum 60-second cooldown between resend requests.
- **Sliding-Window Rate Limiting**: All authentication endpoints (`/register`, `/verify-email`, `/resend-otp`, `/login`) are protected by per-IP and per-endpoint throttling.
- **Protected Route Guards**: Both the Express `protect` middleware and the React `ProtectedRoute` reject unverified accounts.

---

## ⚙️ Environment Configuration

### Backend (`server/.env`)

Configure the following variables in `server/.env` (see `server/.env.example`):

```bash
PORT=5000
MONGODB_URI=mongodb+srv://<username>:<password>@cluster.mongodb.net/devops_db?retryWrites=true&w=majority
JWT_SECRET=your_jwt_secret_key_here
JWT_EXPIRES_IN=7d
GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com

# Email OTP Delivery (Nodemailer SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
EMAIL_FROM="DevOps Learning Platform" <noreply@devops.example.com>

# Local Dev & Automated Testing flag
# Set to 'true' to use the in-memory mock email transport during local dev/tests without live SMTP
USE_MOCK_EMAIL=true
```

### Frontend (`web/.env`)

```bash
VITE_API_URL=http://localhost:5000/api
VITE_GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
```

> **Security Note:** Both `server/.env` and `web/.env` are strictly excluded from Git via `.gitignore`.

---

## 🚀 Running the Project

### 1. Install Dependencies

```bash
# Backend
cd server
npm install

# Frontend
cd ../web
npm install
```

### 2. Run the Backend API

```bash
cd server
npm run dev
# Server starts on http://localhost:5000
```

### 3. Run the Frontend Client

```bash
cd web
npm run dev
# Vite server starts on http://localhost:5173
```

### 4. Run Automated Tests

```bash
# Backend OTP & Auth Suite (19 automated tests)
cd server
npm test

# Frontend Linting & Production Build
cd ../web
npm run lint
npm run build
```

---

## 🛠️ UI UX Pro Max Skill Installation

The **UI UX Pro Max** skill was installed into Antigravity via the official `uipro-cli`:

```bash
npx -y uipro-cli init -a antigravity
```

The design system was generated and persisted via:

```bash
python .agent/skills/ui-ux-pro-max/scripts/search.py "developer devops learning platform saas modern" --design-system --persist -p "DevOps Learning Platform"
```

Master configuration is preserved in `design-system/devops-learning-platform/MASTER.md`.

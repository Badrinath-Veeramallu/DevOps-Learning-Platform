# 00 — Project Overview & Architecture Blueprint

Welcome to the **DevOps Learning Platform Mobile App** development journey! This document is your comprehensive foundation guide for the mobile application. Whether you are completely new to mobile development, Flutter, or Dart, this guide begins from absolute first principles and walks through how the mobile app connects to our existing full-stack architecture.

---

## 1. Phase Overview: Phase 0 (Repository Audit & System Architecture)

### What Was Audited
Before writing any application code, we performed a thorough inspection of the entire repository:
1. **Existing Web Application (`web/`)**: React 19 + Vite 8 single-page application using React Router 7, native CSS design system with Cyber Midnight dark developer theme.
2. **Existing Backend API (`server/`)**: Node.js + Express 5 + MongoDB/Mongoose with JWT authentication, cryptographically secure 6-digit OTP verification, rate limiting, and Google OAuth 2.0 verification.
3. **Existing Design System (`design-system/`) & CSS Tokens**: Audited the design tokens in `design-system/devops-learning-platform/MASTER.md` and `web/src/index.css`.
4. **Existing Flutter Project (`devops_learning_app/`)**: Discovered an existing Flutter project at repository root containing Flutter 3.47 / Dart 3.13 configuration, default counter application, and initial dependencies (`dio`, `go_router`, `flutter_secure_storage`, `provider`).
5. **System Toolchain & Baseline Checks**: Tested Flutter CLI, Dart CLI, `oxlint`, Vite build, and audited local port bindings and native compiler toolchains.

### Why This Phase Was Necessary
In professional engineering, leaping directly into code without auditing existing contracts leads to broken integrations, duplicated databases, conflicting authentication states, and violated constraints. Phase 0 guarantees:
- The React web platform remains completely protected and untouched.
- The existing backend API is verified to fully support mobile clients without any server modifications.
- Network and mobile environment differences (such as Android emulator loopbacks) are mapped out before writing API services.
- A beginner-friendly educational roadmap is established so you learn Flutter while the app is built.

---

## 2. Flutter & Dart Concepts from Absolute Basics

If you are brand new to Flutter and Dart, here are the essential mental models:

### What is Flutter?
Flutter is Google's open-source UI software development kit (SDK). Unlike web applications that run in a browser or inside an embedded web view (like Electron or Cordova), Flutter compiles your code directly into native ARM/x86 machine instructions and renders every pixel onto the screen using high-performance graphics engines (Impeller or Skia).
- **One codebase, multiple targets**: The exact same Dart code runs on Android, iOS, Desktop (macOS, Windows, Linux), and Web.
- **Pixel-level control**: Flutter does not wrap native Android XML views. Instead, Flutter draws its own UI widgets directly onto a canvas, ensuring uniform appearance across all Android OS versions.

### What is Dart?
Dart is the client-optimized programming language created by Google that powers Flutter.
Key characteristics of Dart:
1. **Type-safe with Sound Null Safety**: Dart catches type errors and null reference bugs at compile time before your app ever runs on a device.
2. **Object-Oriented**: Everything in Dart is an object, including numbers, strings, and functions. Every object is an instance of a `Class`.
3. **Just-In-Time (JIT) & Ahead-Of-Time (AOT) Compilation**:
   - During development, Dart uses JIT compilation with a VM to provide **Stateful Hot Reload** (sub-second UI updates without losing app state).
   - In production release builds, Dart uses AOT compilation directly into machine code for fast startup and 60/120 FPS performance.

### Core Dart Concepts You Must Know

#### 1. Variables and Type Annotations
```dart
String appName = 'DevOps Learning Platform';
int port = 5000;
double progress = 0.75;
bool isEmailVerified = true;
```
Dart can also infer types using `var`, but explicit types or `final` are preferred in production code:
```dart
var username = 'Alice'; // Dart infers String
```

#### 2. `final` vs `const`
- `final`: A variable whose value can be set once, but that value can be calculated at runtime (e.g. `final currentTime = DateTime.now();`).
- `const`: A compile-time constant. Its value must be known before the program runs (e.g. `const int timeoutSeconds = 30;`). In Flutter, using `const` on widgets tells Flutter that the widget will never change, allowing Flutter to cache it and avoid re-rendering it!

#### 3. Null Safety
In Dart, variables cannot be `null` by default:
```dart
String title = 'DevOps'; // Can NEVER be null!
// title = null; // COMPILE ERROR!
```
To allow a variable to hold `null`, add a question mark `?`:
```dart
String? avatarUrl; // Can be a String OR null!
```
To access a nullable variable safely:
```dart
int length = avatarUrl?.length ?? 0; // If avatarUrl is null, fallback to 0
```

#### 4. Asynchronous Programming: `Future`, `async`, and `await`
When mobile apps fetch data over the network, the app cannot freeze while waiting for the server. Dart uses single-threaded event loops with `Future` objects (equivalent to JavaScript `Promise`):
```dart
Future<Map<String, dynamic>> fetchUserProfile() async {
  try {
    final response = await dio.get('/auth/me');
    return response.data;
  } catch (error) {
    throw Exception('Failed to load profile');
  }
}
```

---

## 3. High-Level System Architecture

Our platform adheres strictly to the single source of truth architecture:

```text
               +--------------------------------------+
               |      Existing MongoDB Database       |
               | (Users, Hashed Passwords, OTP State) |
               +--------------------------------------+
                                  ^
                                  |
               +--------------------------------------+
               |     Existing Express API Server      |
               |      (Node.js / Mongoose / JWT)      |
               |             Port: 5000               |
               +--------------------------------------+
                                  ^
                  +---------------+---------------+
                  |                               |
       HTTP/JSON Requests              HTTP/JSON Requests
       (Authorization: Bearer)         (Authorization: Bearer)
                  |                               |
                  v                               v
    +---------------------------+   +---------------------------+
    |    Existing React Web     |   |   New Flutter Android     |
    |      (Vite Frontend)      |   |        (Mobile App)       |
    |  - Path: web/             |   |  - Path: mobile/          |
    |  - Browser localStorage   |   |  - flutter_secure_storage |
    +---------------------------+   +---------------------------+
```

### Shared Account Lifecycle
1. A user signs up on the React website or in the Flutter Android app.
2. The user receives a 6-digit OTP email from the Express backend.
3. The user submits the 6-digit code.
4. Once verified, the exact same account can seamlessly sign in on both the web application and the Android mobile app.
5. No second database is created. No separate mobile authentication server exists.

---

## 4. API Endpoints & Response Contracts Audit

The Express backend was verified directly in `server/src/controllers/authController.js` and `server/src/routes/authRoutes.js`. Here are the exact live contracts:

### 1. Register Account
- **Endpoint**: `POST /api/auth/register`
- **Rate Limit**: Max 10 attempts per 15 minutes per IP.
- **Request Body**:
  ```json
  {
    "name": "Alex Mercer",
    "email": "alex@example.com",
    "password": "Password123!"
  }
  ```
- **Backend Rules**: Name required (2-50 chars), email valid format, password >= 8 chars.
- **Success Response (`HTTP 201 Created`)**:
  ```json
  {
    "success": true,
    "message": "Verification code sent to your email. Please verify your account.",
    "email": "alex@example.com",
    "requireOtp": true
  }
  ```
- **Error Responses**:
  - `HTTP 400 Bad Request`: `{ "success": false, "message": "Password must be at least 8 characters long" }`
  - `HTTP 409 Conflict`: `{ "success": false, "message": "An account with this email address already exists" }`
  - `HTTP 503 / 500`: `{ "success": false, "code": "SMTP_NOT_CONFIGURED", "message": "...", "canRetry": true }`

### 2. Verify Email OTP
- **Endpoint**: `POST /api/auth/verify-email`
- **Rate Limit**: Max 20 attempts per 15 minutes.
- **Request Body**:
  ```json
  {
    "email": "alex@example.com",
    "otp": "492810"
  }
  ```
- **Backend Rules**: 6 numeric digits, expires after 10 minutes (`OTP_EXPIRY_MS`), max 5 failed attempts per OTP code (`MAX_ATTEMPTS`).
- **Success Response (`HTTP 200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Email verified successfully",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "673f8a...",
      "name": "Alex Mercer",
      "email": "alex@example.com",
      "role": "user",
      "avatar": ""
    }
  }
  ```
- **Error Responses**:
  - `HTTP 400 Bad Request`: `{ "success": false, "message": "Invalid verification code. 4 attempt(s) remaining." }`
  - `HTTP 400 Bad Request`: `{ "success": false, "message": "Verification code has expired. Please request a new code." }`
  - `HTTP 400 Bad Request`: `{ "success": false, "message": "Too many failed attempts. This code is invalidated. Please request a new code." }`

### 3. Resend OTP
- **Endpoint**: `POST /api/auth/resend-otp`
- **Rate Limit**: Max 6 attempts per 15 minutes, with a 60-second cooldown between requests (`RESEND_COOLDOWN_MS = 60000`).
- **Request Body**:
  ```json
  {
    "email": "alex@example.com"
  }
  ```
- **Success Response (`HTTP 200 OK`)**:
  ```json
  {
    "success": true,
    "message": "A new verification code has been sent to your email."
  }
  ```
- **Cooldown Rejection (`HTTP 429 Too Many Requests`)**:
  ```json
  {
    "success": false,
    "message": "Please wait 42 second(s) before requesting another code.",
    "retryAfter": 42
  }
  ```

### 4. Login
- **Endpoint**: `POST /api/auth/login`
- **Rate Limit**: Max 15 attempts per 15 minutes.
- **Request Body**:
  ```json
  {
    "email": "alex@example.com",
    "password": "Password123!"
  }
  ```
- **Success Response (`HTTP 200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Login successful",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "673f8a...",
      "name": "Alex Mercer",
      "email": "alex@example.com",
      "role": "user",
      "avatar": ""
    }
  }
  ```
- **Unverified Account Response (`HTTP 403 Forbidden`)**:
  ```json
  {
    "success": false,
    "message": "Your email address is not verified. Please verify your email before signing in.",
    "isEmailVerified": false,
    "email": "alex@example.com"
  }
  ```
  *Mobile Note*: When receiving HTTP 403 with `isEmailVerified: false`, our Flutter app will automatically redirect the user to the OTP verification screen!

### 5. Get Authenticated User Profile
- **Endpoint**: `GET /api/auth/me`
- **Headers**: `Authorization: Bearer <JWT_TOKEN>`
- **Success Response (`HTTP 200 OK`)**:
  ```json
  {
    "success": true,
    "user": {
      "_id": "673f8a...",
      "name": "Alex Mercer",
      "email": "alex@example.com",
      "avatar": "",
      "role": "user",
      "authProvider": "local",
      "googleId": null,
      "isEmailVerified": true,
      "createdAt": "2026-10-24T18:00:00.000Z",
      "updatedAt": "2026-10-24T18:05:00.000Z"
    }
  }
  ```
  *Crucial Integration Note*: In `login` and `verifyEmail`, the user ID is returned under the key `id`. In `/auth/me`, the Mongoose user document is serialized with key `_id`. Our Flutter Dart model must handle both `json['id'] ?? json['_id']` safely!

---

## 5. Mobile vs Web: Network & Storage Differences

### Why Android Emulator Cannot Use `localhost:5000`
On your Mac, `localhost` refers to your Mac's own network loopback adapter (`127.0.0.1`).
However, when you run an Android Emulator, the emulator runs inside its own virtual machine with its own virtual network. Inside the Android VM:
- `localhost` (or `127.0.0.1`) refers to the **Android virtual device itself**, NOT your Mac!
- Google designed a special virtual router alias for Android emulators: **`10.0.2.2`**.
- Connecting to `http://10.0.2.2:5000/api` from inside the Android emulator routes network traffic directly to `localhost:5000` on your host Mac!
- If testing on a **physical Android phone connected via Wi-Fi**, the app must connect to your Mac's LAN IP address (e.g. `http://192.168.1.50:5000/api`).

### Storage Security: `localStorage` vs `flutter_secure_storage`
- **Web App**: Stores the JWT in browser `localStorage`. While standard for SPAs, it is theoretically readable by client-side scripts.
- **Flutter Android App**: Uses `flutter_secure_storage`. On Android, this utilizes the **Android KeyStore** and **EncryptedSharedPreferences** with AES-256 GCM encryption. Even if an attacker gains root access to the device file system, the encryption keys remain protected in the hardware security module (Keymaster/StrongBox).

---

## 6. Design System Adaptation: Cyber Midnight

The web platform features the **Cyber Midnight** theme (`web/src/index.css`). We are porting these exact color and typography tokens directly into our Flutter theme system:

| UI Role | Hex Value | Flutter `Color` Representation |
|---|---|---|
| Background Canvas | `#090D16` | `const Color(0xFF090D16)` |
| Card / Surface | `#111827` | `const Color(0xFF111827)` |
| Elevated Surface | `#1E293B` | `const Color(0xFF1E293B)` |
| Primary Accent (Cyan) | `#22D3EE` | `const Color(0xFF22D3EE)` |
| Secondary Accent (Lime) | `#A3E635` | `const Color(0xFFA3E635)` |
| Primary Text | `#F1F5F9` | `const Color(0xFFF1F5F9)` |
| Muted Subtext | `#94A3B8` | `const Color(0xFF94A3B8)` |
| Error / Danger | `#EF4444` | `const Color(0xFFEF4444)` |
| Warning | `#F59E0B` | `const Color(0xFFF59E0B)` |

---

## 7. Baseline Verification & Toolchain Diagnostics

During the audit, we executed and recorded the following baselines:
1. **Web App Linter**: `npm run lint` in `web/` passed with 0 errors across 24 files.
2. **Web Production Build**: `npm run build` in `web/` compiled successfully in 635ms.
3. **Flutter Static Analysis**: `flutter analyze` in `devops_learning_app` passed with 0 issues.
4. **macOS Host Test Native Linker Diagnostic**: Running `flutter test` on macOS host currently triggers a native asset linker issue in Apple CommandLineTools (`MacOSX27.0.sdk` `arm64e.x1-macos` tbd parsing error in `objective_c` build hook). This does NOT affect Android compilation or runtime execution, but pure unit tests and Android builds bypass this cleanly.
5. **Local Port 5000 Audit**: macOS AirPlay Receiver in `ControlCenter` is actively listening on port 5000. When launching the backend, we must ensure either AirPlay Receiver is toggled off or `PORT=5001` (with matching mobile base URL) is utilized.

---

## 8. Learning Exercises (Phase 0)

Try answering these questions before checking the answers below!

1. **Question 1**: What is the difference between `final` and `const` in Dart, and why does Flutter encourage using `const` before widget constructors?
2. **Question 2**: If the backend sends `{ "user": { "_id": "123" } }` on `/api/auth/me` and `{ "user": { "id": "123" } }` on `/api/auth/login`, what Dart syntax allows us to read either safely?
3. **Question 3**: Why does `http://localhost:5000/api` fail when invoked from an Android emulator, and what IP address must be used instead?
4. **Question 4**: Why must the mobile app store the authentication JWT in `flutter_secure_storage` instead of plain `SharedPreferences`?
5. **Question 5**: If a user attempts to log in with correct credentials but their account is not verified, what HTTP status code does our Express server return, and how should the mobile app respond?

---

### Exercise Answers

- **Answer 1**: `const` values must be fully determined at compile time, whereas `final` values can be computed at runtime but can only be assigned once. Using `const` on Flutter widgets tells the framework that the widget instance will never change, allowing Flutter to reuse the existing instance and skip rebuilding it when parent widgets update.
- **Answer 2**: `final id = json['id'] as String? ?? json['_id'] as String? ?? '';` uses Dart's null-coalescing operator `??` to check for `id` first, then fall back to `_id`, and default to empty string if both are missing.
- **Answer 3**: The Android emulator runs inside its own virtual machine with its own loopback interface; `localhost` in the emulator refers to the virtual phone itself. Google maps `10.0.2.2` to route directly to the host machine's `127.0.0.1`.
- **Answer 4**: Plain `SharedPreferences` stores data in unencrypted XML files in the app sandbox. `flutter_secure_storage` uses the Android KeyStore and hardware-backed AES-256 encryption, preventing unauthorized access or token theft if the device or backups are compromised.
- **Answer 5**: The Express backend returns `HTTP 403 Forbidden` with `{ "isEmailVerified": false, "email": "..." }`. The mobile app should intercept this 403 response, extract the email address, and immediately navigate the user to the OTP verification screen so they can complete verification.

---

## 9. Revision Notes & Glossary

- **Widget**: The fundamental building block of a Flutter UI. Every element (buttons, text, layout containers, themes) is a widget.
- **Widget Tree**: The hierarchical nested structure representing your visual application layout.
- **State**: The data or condition of your application that can change over time (e.g. current user, loading spinner, error text).
- **StatelessWidget**: A widget that does not require mutable state; it builds its UI solely from its configuration parameters.
- **StatefulWidget**: A widget that maintains mutable state across frames through an associated `State` object.
- **Sound Null Safety**: Dart's guarantee that a non-nullable type cannot under any circumstance evaluate to `null`.
- **KeyStore**: Android's secure hardware/system service for generating and storing cryptographic keys that cannot be extracted by apps.

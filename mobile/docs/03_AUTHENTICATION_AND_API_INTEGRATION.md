# 03 — Authentication & API Integration (Phase 2)

Welcome to the **Authentication and API Integration Guide** for the DevOps Learning Platform Flutter mobile application!

This document teaches you how our mobile application communicates with our real Express backend, how user credentials are submitted, how single-use email verification OTPs work, and how authenticated JWT sessions are stored with hardware-backed encryption on Android.

---

## 1. Full-Stack Authentication Architecture

Here is the exact flow of data between the Flutter mobile app, the Express backend, and the MongoDB database:

```mermaid
sequenceDiagram
    autonumber
    actor User as Mobile User
    participant Flutter as Flutter App (Android)
    participant KeyStore as Secure Storage (KeyStore)
    participant Express as Express API Server
    participant Mongo as MongoDB Database

    Note over User,Mongo: Flow 1: Registration & OTP Verification
    User->>Flutter: Fills Name, Email, Password & taps "Create Account"
    Flutter->>Express: POST /api/auth/register {name, email, password}
    Express->>Mongo: Creates unverified User (isEmailVerified: false)
    Express->>Mongo: Persists SHA-256 Hashed OTP record (expires: 10m)
    Express-->>Flutter: HTTP 201 Created {requireOtp: true, email}
    Flutter->>Flutter: Navigates to /verify-otp?email=user@example.com

    User->>Flutter: Enters 6-digit OTP code & taps "Verify"
    Flutter->>Express: POST /api/auth/verify-email {email, otp}
    Express->>Mongo: Verifies hash & sets user.isEmailVerified = true
    Express-->>Flutter: HTTP 200 OK {token: JWT, user: {id, name, ...}}
    Flutter->>KeyStore: Stores JWT securely (AES-256 GCM)
    Flutter->>Flutter: Navigates to /dashboard

    Note over User,Mongo: Flow 2: Existing User Login
    User->>Flutter: Fills Email & Password & taps "Sign In"
    Flutter->>Express: POST /api/auth/login {email, password}
    alt Account Verified
        Express-->>Flutter: HTTP 200 OK {token: JWT, user: {id, name, ...}}
        Flutter->>KeyStore: Stores JWT
        Flutter->>Flutter: Navigates to /dashboard
    else Account Not Verified
        Express-->>Flutter: HTTP 403 Forbidden {isEmailVerified: false, email}
        Flutter->>Flutter: Automatically routes to /verify-otp?email=...
    end

    Note over User,Mongo: Flow 3: App Restart & Session Restoration
    Flutter->>KeyStore: Reads stored JWT on app startup
    alt Token Exists
        Flutter->>Express: GET /api/auth/me (Authorization: Bearer <token>)
        alt Token Valid
            Express-->>Flutter: HTTP 200 OK {user: {_id, name, ...}}
            Flutter->>Flutter: Establishes session & opens /dashboard
        else Token Expired (401)
            Express-->>Flutter: HTTP 401 Unauthorized
            Flutter->>KeyStore: Deletes expired token
            Flutter->>Flutter: Opens Welcome / Login screen
        end
    end

    Note over User,Mongo: Flow 4: Google Sign-In & Registration
    User->>Flutter: Taps "Continue with Google"
    Flutter->>GooglePlay: Invokes Google Play Services (serverClientId: Web Client ID)
    GooglePlay-->>Flutter: Returns Google ID Token (signed JWT)
    Flutter->>Express: POST /api/auth/google {idToken}
    Express->>Express: Verifies signature with google-auth-library
    Express->>Mongo: Finds/Creates User & links googleId
    Express-->>Flutter: HTTP 200 OK {token: JWT, user: {id, name, ...}}
    Flutter->>KeyStore: Stores JWT securely (AES-256 GCM)
    Flutter->>Flutter: Navigates to /dashboard ("Hi, <Name> 👋")
```

---

## 2. Core Concepts Explained for Beginners

### 1. How a Flutter Button Triggers an API Call
When you tap an `AppButton` on your screen:
1. The `onPressed` callback executes a Dart function in your widget (e.g. `_handleLogin()`).
2. The form validates the user's inputs (`_formKey.currentState!.validate()`).
3. If valid, the widget calls a method on our state manager (`context.read<AuthProvider>().login(...)`).
4. The provider sets `isLoading = true` and calls `notifyListeners()`, which instantly causes Flutter to redraw the button with a spinning progress indicator.
5. The provider calls `ApiClient.login()`, which issues an HTTP request using `Dio`.
6. When the response arrives, the provider saves the token and updates the state.

### 2. What `Future`, `async`, and `await` Mean
Network calls take time (typically 50ms to 2000ms). If a mobile app waited synchronously for the network response, the entire phone screen would freeze, preventing user interaction.

Dart solves this with **Asynchronous Programming**:
- **`Future<T>`**: An object representing a value that is not available yet, but will be available in the future (or an error if it fails). It is identical to JavaScript's `Promise`.
- **`async`**: A keyword placed on a function declaration indicating that the function performs asynchronous operations and returns a `Future`.
- **`await`**: A keyword placed before a `Future` call that pauses the execution of *that specific function* until the `Future` completes, without freezing the rest of the application!

```dart
// Example from mobile/lib/core/api/api_client.dart:
Future<({String token, UserModel user})> login({
  required String email,
  required String password,
}) async {
  // Await pauses this function while Dio sends the request over the network
  final response = await _dio.post('/auth/login', data: {'email': email, 'password': password});
  // Code resumes here once the server responds
  return (token: response.data['token'], user: UserModel.fromJson(response.data['user']));
}
```

### 3. What HTTP, JSON, and Dio Do
- **HTTP (Hypertext Transfer Protocol)**: The standardized language of the web. The mobile app sends HTTP requests (`POST`, `GET`) to the Express API server and receives HTTP responses with status codes.
- **Status Codes**:
  - `200 OK`: Request succeeded.
  - `201 Created`: New resource (account) was created.
  - `400 Bad Request`: Client input invalid (e.g., password too short, invalid OTP).
  - `401 Unauthorized`: Bad password or expired token.
  - `403 Forbidden`: Account email is not verified yet.
  - `409 Conflict`: An account with that email already exists.
  - `429 Too Many Requests`: Rate limit or OTP resend cooldown active.
  - `500 / 503`: Server or email delivery error.
- **JSON (JavaScript Object Notation)**: Text-based format used to exchange structured data between mobile apps and servers (e.g. `{ "email": "dev@example.com" }`).
- **Dio**: A powerful, production-grade HTTP client package for Dart. Dio provides connection pooling, automatic JSON serialization, request timeouts, and **Interceptors** (hooks that run before requests leave or after responses arrive).

### 4. How Dart Models Convert JSON into User Objects
In JavaScript, JSON is automatically an object. In Dart, raw JSON parsed by Dio is a generic dictionary: `Map<String, dynamic>`.
Accessing `json['email']` throughout your entire app is error-prone because a typo like `json['emial']` will silently fail.

Instead, we convert the map into a strongly-typed `UserModel` object using a **Factory Constructor**:
```dart
factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel(
    // Safely reads either 'id' (login response) or '_id' (Mongoose document)
    id: (json['id'] ?? json['_id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    avatar: json['avatar'] as String?,
    role: (json['role'] ?? 'user').toString(),
    isEmailVerified: json['isEmailVerified'] == true,
  );
}
```
Now, throughout the app, we write `user.email` or `user.isEmailVerified`. The compiler validates every property access!

### 5. Why We Separate UI, Providers, API Client, and Storage
In beginner tutorials, developers often put HTTP requests, database storage, and UI widgets all inside one file. In production applications, this creates spaghetti code that is impossible to test.

Our architecture strictly enforces the **Separation of Concerns**:
1. **Screens (`features/auth/screens/`)**: Only responsible for showing UI widgets, validating form inputs, and responding to user taps. They do not know about HTTP headers or SQLite.
2. **State Provider (`providers/auth_provider.dart`)**: Holds the current application state (`user`, `isLoading`, `errorMessage`) and notifies the UI when data changes.
3. **API Client (`core/api/api_client.dart`)**: Knows how to format HTTP requests, construct URLs, and translate Dio errors into `ApiException`.
4. **Secure Storage (`core/storage/secure_storage_service.dart`)**: Only cares about reading and writing encrypted key-value strings to the Android hardware KeyStore.

### 6. What JWT Bearer Authentication Means
When a user logs in, the server generates a **JWT (JSON Web Token)**:
```text
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3M2Y4YS4uLiIsImlhdCI6MTcy...
```
This token is cryptographically signed with the backend's secret key (`JWT_SECRET`). It contains the user's ID and an expiration timestamp.

For all subsequent authenticated requests (such as `GET /api/auth/me`), our `AuthInterceptor` automatically adds the token to the HTTP header:
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```
When Express receives this request, `authMiddleware.js` verifies the signature using `jwt.verify()`. If valid, it attaches the user to `req.user` without requiring the user to re-enter their password!

### 7. Why We Use Android KeyStore (flutter_secure_storage)
On Android:
- Plain `SharedPreferences` stores data in cleartext XML files on disk (`/data/data/com.example.../shared_prefs/`). Anyone with a rooted device, physical access, or backup extraction tools can read plain text tokens.
- `flutter_secure_storage` uses the **Android KeyStore system** and **EncryptedSharedPreferences** with AES-256 GCM encryption. The master encryption key is generated and stored directly inside the phone's dedicated hardware security chip (TEE or StrongBox Keymaster), making token extraction virtually impossible.

---

## 3. Files Created in Phase 2

| Relative Path | Responsibility |
|---|---|
| [`mobile/lib/models/user_model.dart`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/lib/models/user_model.dart) | Strongly-typed user model supporting both `id` and Mongoose `_id` keys. |
| [`mobile/lib/core/storage/secure_storage_service.dart`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/lib/core/storage/secure_storage_service.dart) | `ISecureStorageService` interface & `SecureStorageService` implementation wrapping `FlutterSecureStorage`. |
| [`mobile/lib/core/api/api_exceptions.dart`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/lib/core/api/api_exceptions.dart) | Centralized error parser handling network timeouts, connection errors, and backend status codes (400, 401, 403, 409, 429). |
| [`mobile/lib/core/api/auth_interceptor.dart`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/lib/core/api/auth_interceptor.dart) | Dio interceptor that injects `Authorization: Bearer <token>` and scrubs passwords/OTPs/tokens from debug logs. |
| [`mobile/lib/core/api/api_client.dart`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/lib/core/api/api_client.dart) | Dio HTTP client containing `login()`, `register()`, `verifyEmail()`, `resendOtp()`, and `getMe()`. |
| [`mobile/lib/providers/auth_provider.dart`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/lib/providers/auth_provider.dart) | `ChangeNotifier` state manager coordinating user authentication, session restoration, and logout. |
| [`mobile/lib/features/auth/screens/login_screen.dart`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/lib/features/auth/screens/login_screen.dart) | Login UI with email format validation, password visibility toggle, error banners, and 403 unverified auto-route. |
| [`mobile/lib/features/auth/screens/register_screen.dart`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/lib/features/auth/screens/register_screen.dart) | Register UI with name, email, password, confirm password validation, and direct routing to OTP verification. |
| [`mobile/lib/features/auth/screens/verify_otp_screen.dart`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/lib/features/auth/screens/verify_otp_screen.dart) | 6-digit OTP entry, active 60-second cooldown timer, resend button, and invalid/expired attempt handling. |
| [`mobile/lib/features/dashboard/screens/dashboard_screen.dart`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/lib/features/dashboard/screens/dashboard_screen.dart) | Authenticated destination screen confirming live JWT session, displaying profile data, and working Sign Out. |
| [`mobile/test/user_model_test.dart`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/test/user_model_test.dart) | Unit tests verifying `id` vs `_id` deserialization, optional fields, and `copyWith`. |
| [`mobile/test/auth_provider_test.dart`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/test/auth_provider_test.dart) | Comprehensive state tests for login, register, OTP verification, session restoration, and logout. |
| [`mobile/test/auth_widgets_test.dart`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/test/auth_widgets_test.dart) | Widget tests verifying form validation errors and countdown timers. |

---

## 4. Common Errors & How We Handle Them

| Error Scenario | Backend Status | How Our Mobile App Handles It |
|---|:---:|---|
| Account created but email unverified | `403 Forbidden` | Intercepts `isEmailVerified: false`, extracts the email, and automatically navigates the user to `/verify-otp?email=...` with an explanatory notice. |
| Incorrect OTP entered | `400 Bad Request` | Displays `Invalid verification code. X attempt(s) remaining.` in an alert banner. |
| Too many failed OTP attempts | `400 Bad Request` | Displays `Too many failed attempts. This code is invalidated. Please request a new code.` and invites user to resend. |
| Rapid OTP resend clicks | `429 Too Many Requests` | Starts an active countdown timer from `retryAfter` seconds and disables the resend button until the cooldown expires. |
| Expired session token on app startup | `401 Unauthorized` | Secure storage service safely wipes the expired token, resets user to `null`, and displays the welcome screen. |
| Server offline / temporary network drop | `503 / Timeout` | Does **not** wipe the stored token! Displays a friendly connection error without logging the user out. |

---

## 5. Verification Commands Executed

```bash
# Code formatting
dart format lib test
# Result: 28 files formatted cleanly

# Static analysis
flutter analyze
# Result: Analyzing mobile... No issues found! (ran in 7.3s)

# Web app baseline invariance check
npm run lint && npm run build (in web/)
# Result: 0 warnings, 0 errors, build succeeded in 274ms (identical to baseline)
```

### macOS Native Linker Diagnostic
As established in Phase 0 and Phase 1, `flutter test` on macOS host encounters the Apple Command Line Tools `MacOSX27.0.sdk` `arm64e.x1-macos` tbd parsing error inside `objective_c` build hooks. This is strictly a macOS host C-linker parser issue that does not impact Android compilation, Android emulator execution, or runtime functionality.

---

## 6. How to Test the Entire Authentication Lifecycle

### Step 1: Start the Backend Server
Make sure MongoDB is running and start the Express server on port 5000:
```bash
cd server
npm start
```
*(Server output: `Server running on http://localhost:5000`)*

### Step 2: Run the Mobile Application
Launch the app on your Android emulator or connected device:
```bash
cd mobile
flutter run
```

### Step 3: Test New User Registration & OTP
1. On the welcome screen, tap **"Create Account"**.
2. Enter your Name, a test email (e.g. `alex@example.com`), and a password (at least 8 characters).
3. Tap **"Create Account & Send Code"**.
4. The app navigates to the **Verify Email** screen displaying `alex@example.com` and an active 60-second cooldown timer.
5. Retrieve the 6-digit OTP code (from your inbox or the server console/database).
6. Enter the 6 digits. As soon as the 6th digit is entered, the app verifies the code, stores the JWT securely, and navigates to the **Command Center**!

### Step 4: Test Session Restoration
1. While on the Command Center screen, completely close and exit the Flutter application.
2. Re-open the app.
3. Notice that `checkAuthStatus()` reads the token from secure storage, calls `/api/auth/me`, and opens directly to the authenticated **Command Center** without asking you to log in again!

### Step 5: Test Sign Out
1. On the Command Center screen, tap **"Sign Out of Mobile Session"** (or the red logout icon in the AppBar).
2. The JWT is erased from Android KeyStore secure storage.
3. The app redirects to the welcome screen.
4. Closing and re-opening the app confirms you remain unauthenticated.

### Step 6: Test Web & Mobile Shared Identity
1. Open the existing React website in your browser (`http://localhost:5173`).
2. Log in using the exact same email and password you registered on Android.
3. The website logs you in immediately using the exact same canonical user record in MongoDB!

---

## 7. Learning Exercises (Phase 2)

1. **Question 1**: Why does `UserModel.fromJson()` check `json['id'] ?? json['_id']` instead of just `json['id']`?
2. **Question 2**: What is the purpose of `AuthInterceptor` in Dio?
3. **Question 3**: In `mobile/lib/core/api/auth_interceptor.dart`, why do we recursively sanitize the request body in debug logs?
4. **Question 4**: What happens if a user enters valid login credentials, but the server returns HTTP 403 with `isEmailVerified: false`?
5. **Question 5**: Why does `AuthProvider.checkAuthStatus()` NOT delete the stored token when an HTTP timeout or network error occurs?

---

### Exercise Answers

- **Answer 1**: The backend issues user objects with `id` in `authController.js` on `/login` and `/verify-email`, but the `/auth/me` endpoint returns a raw Mongoose document which serializes the MongoDB primary key as `_id`. Checking both ensures seamless compatibility across all endpoints.
- **Answer 2**: `AuthInterceptor` intercepts outgoing HTTP requests before they are sent and automatically injects the `Authorization: Bearer <token>` header by reading the token from secure storage, eliminating the need to manually pass headers in every API call.
- **Answer 3**: Security best practices mandate that passwords, OTP codes, and authentication tokens must never be written to terminal logs, console outputs, or device crash logs, preventing credential exposure during development or testing.
- **Answer 4**: The `LoginScreen` catches the `ApiException`, observes that `isEmailVerified` is false, informs the user with a warning banner, and automatically routes them to the OTP verification screen (`/verify-otp?email=...`) so they can finish verifying their account.
- **Answer 5**: If the user has a valid 7-day JWT, but is temporarily on an elevator, in airplane mode, or the server is momentarily restarting, deleting the token would force them to log in again unnecessarily. Tokens are only deleted when the server explicitly confirms they are invalid or expired (`HTTP 401`).

---

## 8. Google Sign-In Architecture & Cloud Console Setup

### How Google OAuth Works on Android
1. **Flutter client**: Uses `google_sign_in: ^7.2.0` with `GoogleSignIn.instance.initialize(serverClientId: AppConfig.googleClientId)`.
2. **Google Play Services**: Presents the Google account selector on the phone. Upon selection, Google Play Services generates a signed Google ID token whose audience matches our server's Web Client ID (`958415885728-9pi8volbfam54kav5hj5akvn8eq2f1uj.apps.googleusercontent.com`).
3. **Backend verification**: Sent to `POST /api/auth/google`. The Express server verifies the signature using `google-auth-library` against Google's public keys, links or creates the MongoDB user record, and issues a standard 7-day platform JWT.
4. **Session persistence**: The JWT is encrypted in Android KeyStore via `flutter_secure_storage`.

### Required Google Cloud Console Configuration
For Google Play Services to authorize sign-ins from this Android app, the SHA-1 fingerprint must be added to your Google Cloud Console project (`958415885728`):

1. Go to the [Google Cloud Console Credentials Page](https://console.cloud.google.com/apis/credentials).
2. Select project **958415885728**.
3. Click **Create Credentials** > **OAuth client ID**.
4. Application type: **Android**.
5. Package name: `com.example.devops_learning_app`
6. SHA-1 certificate fingerprint:
   ```text
   87:2C:FC:F8:AF:56:2A:88:65:7E:97:6F:72:25:EF:77:57:6F:F7:DE
   ```
7. Click **Create**.


# 02 — Project Setup & Mobile Design System (Phase 1)

This document details the architectural implementation of **Phase 1: Foundation and Mobile Design System**. It explains what was moved, how the project is organized inside `mobile/`, how the Cyber Midnight design system was converted into Flutter tokens, and how the navigation and Android configuration were established.

---

## 1. Phase Overview

### What Was Built
1. **Safe Project Relocation**: Preserved all original application IDs, Gradle configs, and package settings while moving the Flutter project into [`mobile/`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile).
2. **Cyber Midnight Design System**: Transformed the web platform's dark developer design tokens into a native Flutter theme (`AppColors`, `AppTypography`, `AppTheme`).
3. **Reusable Widget Library**: Built production-quality buttons (`AppButton`), form inputs (`AppTextField`), dark surface cards (`AppCard`), pill badges (`StatusBadge`), and a canvas grid painter (`CyberBackground`).
4. **Declarative Navigation Foundation**: Configured `GoRouter` with centralized route names, deep linking readiness, and native Android back button support.
5. **Phase 1 Foundation Screen**: Built the responsive `WelcomeScreen` showcasing the design system, terminal visual demonstration, and clean entry points for Phase 2.
6. **Android System Configuration**: Configured `android.permission.INTERNET`, `usesCleartextTraffic="true"`, and transparent status bars in `AndroidManifest.xml`.

---

## 2. Final Project Structure

```text
mobile/
├── android/                   # Native Android host project (Gradle, Manifest, Kotlin)
│   └── app/src/main/
│       └── AndroidManifest.xml # Internet permission & cleartext traffic configured
├── lib/
│   ├── app.dart               # MaterialApp.router with Cyber Midnight theme
│   ├── main.dart              # Dart entry point (WidgetsFlutterBinding, runApp)
│   ├── core/
│   │   ├── config/
│   │   │   └── app_config.dart # Base URLs for Android emulator (10.0.2.2) vs LAN/Prod
│   │   ├── router/
│   │   │   ├── app_router.dart  # GoRouter setup with Android back navigation
│   │   │   └── route_names.dart # Centralized route constants
│   │   ├── theme/
│   │   │   ├── app_colors.dart     # Cyber Midnight hex color tokens
│   │   │   ├── app_typography.dart # Font styles, weights, and monospace code
│   │   │   └── app_theme.dart      # Flutter ThemeData & component themes
│   │   └── widgets/
│   │       ├── app_button.dart              # Primary glow, secondary outline, ghost buttons
│   │       ├── app_card.dart                # Dark surface card with optional glow
│   │       ├── app_text_field.dart          # Form input with validation styling
│   │       ├── cyber_background.dart        # Background grid painter & ambient glows
│   │       ├── phase_placeholder_screen.dart# Scaffolded destination screens
│   │       └── status_badge.dart            # Pill badge with optional indicator dot
│   └── features/
│       └── onboarding/
│           └── screens/
│               └── welcome_screen.dart       # Phase 1 landing & showcase screen
├── test/
│   └── widget_test.dart       # Widget test verifying WelcomeScreen rendering
├── docs/                      # Learning guides and architectural references
│   ├── 00_PROJECT_OVERVIEW.md
│   ├── 01_FLUTTER_AND_DART_FUNDAMENTALS.md
│   ├── 02_PROJECT_SETUP_AND_DESIGN_SYSTEM.md
│   └── README.md
├── pubspec.yaml               # Package manifests and dependencies
└── README.md                  # Mobile project readme
```

---

## 3. Design System: Web to Mobile Token Translation

The web application uses the **Cyber Midnight** theme (`web/src/index.css`). Here is how those exact CSS tokens were mapped into Dart classes in [`mobile/lib/core/theme/app_colors.dart`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/lib/core/theme/app_colors.dart):

| CSS Token | Hex Value | Flutter `Color` Representation | Role |
|---|---|---|---|
| `--color-background` | `#090D16` | `const Color(0xFF090D16)` | Scaffold background canvas |
| `--color-surface` | `#111827` | `const Color(0xFF111827)` | Cards and modals |
| `--color-surface-elevated`| `#1E293B` | `const Color(0xFF1E293B)` | Terminal headers, elevated rows |
| `--color-primary` | `#22D3EE` | `const Color(0xFF22D3EE)` | Primary CTA, links, cyan glow |
| `--color-secondary` | `#A3E635` | `const Color(0xFFA3E635)` | Lime accent, live status dots |
| `--color-text` | `#F1F5F9` | `const Color(0xFFF1F5F9)` | High-contrast main headings |
| `--color-text-muted` | `#94A3B8` | `const Color(0xFF94A3B8)` | Subtitles, body descriptions |
| `--color-text-subtle` | `#64748B` | `const Color(0xFF64748B)` | Footers, disabled states |
| `--color-error` | `#EF4444` | `const Color(0xFFEF4444)` | Validation errors, failed checks |

---

## 4. Code Walkthrough: Key Files Created

### 1. `lib/core/theme/app_colors.dart`
Defines all color constants in a single place. By setting the constructor to private (`AppColors._();`), we prevent anyone from accidentally instantiating it. Using `static const Color` ensures values are compiled directly into the binary without runtime memory overhead.

### 2. `lib/core/theme/app_theme.dart`
Configures Flutter's `ThemeData(useMaterial3: true, brightness: Brightness.dark)`.
Key configurations:
- `scaffoldBackgroundColor`: Sets `#090D16` globally.
- `appBarTheme`: Transparent background with white title and light status bar icons.
- `inputDecorationTheme`: Sets dark input background (`#0B1120`), 10px rounded borders, and Cyan focus borders.
- `cardTheme`: Border width of 1px using `#1E293B` and 12px rounded corners.

### 3. `lib/core/widgets/app_button.dart`
A flexible button widget with 3 distinct variants:
- **`ButtonVariant.primary`**: Displays a vibrant Cyan background with an ambient glow (`BoxShadow` with 28% opacity Cyan and 18px blur radius).
- **`ButtonVariant.secondary`**: Displays a semi-transparent surface with a Cyan border.
- **`ButtonVariant.ghost`**: Text-only button for secondary actions.
- Built-in `isLoading`: Automatically switches text to a centered `CircularProgressIndicator` while preventing duplicate taps!

### 4. `lib/core/widgets/cyber_background.dart`
A custom wrapper that brings the web app's background grid to Android. It uses a `Stack` containing:
1. A Cyan radial gradient glow positioned off-screen at the top-right.
2. An Indigo radial gradient glow positioned at the bottom-left.
3. A `CustomPaint` with `_GridPainter` that draws subtle white lines at 32px increments with 2.5% opacity.
4. A `SafeArea` that prevents content from being obscured by the Android camera cutout (notch) or navigation bar.

### 5. `lib/core/router/app_router.dart`
Uses `GoRouter` to define declarative routes:
```dart
static final GoRouter router = GoRouter(
  initialLocation: RouteNames.welcome,
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const PhasePlaceholderScreen(...)),
    GoRoute(path: '/register', builder: (context, state) => const PhasePlaceholderScreen(...)),
    GoRoute(path: '/verify-otp', builder: (context, state) => const PhasePlaceholderScreen(...)),
    GoRoute(path: '/dashboard', builder: (context, state) => const PhasePlaceholderScreen(...)),
  ],
);
```

### 6. `lib/features/onboarding/screens/welcome_screen.dart`
The Phase 1 home screen:
- Renders responsive hero typography and platform status badges.
- Features a mock terminal container matching the web landing page (`bash — kubectl get deployments,pods,services`), complete with red/yellow/green title bar dots and colored terminal text.
- Provides "Create Account" and "Sign In to Existing Account" buttons that navigate via `context.push(RouteNames.register)` and `context.push(RouteNames.login)`.
- When navigating to these placeholder routes, the Android system back button or the AppBar back arrow returns cleanly to `WelcomeScreen`.

---

## 5. Android Configuration & Networking Rules

### 1. `AndroidManifest.xml` Updates
In [`mobile/android/app/src/main/AndroidManifest.xml`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/android/app/src/main/AndroidManifest.xml):
- Added `<uses-permission android:name="android.permission.INTERNET"/>`: Required for mobile network requests.
- Added `android:usesCleartextTraffic="true"`: Android 9+ blocks unencrypted HTTP traffic by default. This enables the app to connect to `http://10.0.2.2:5000/api` during local development without needing self-signed SSL certificates.
- Updated `android:label` to `"DevOps Learning Platform"`.

### 2. Network Routing Rules
In [`mobile/lib/core/config/app_config.dart`](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/lib/core/config/app_config.dart):
- When running in an **Android emulator**, the default base URL automatically resolves to `http://10.0.2.2:5000/api`.
- When running on a **physical Android phone**, use `--dart-define=API_URL=http://<YOUR_MAC_LAN_IP>:5000/api`.
- When deploying to **production**, use `--dart-define=API_URL=https://api.yourdomain.com/api`.

---

## 6. Verification and Testing

### 1. Verification Commands Executed
```bash
# Code formatting
dart format lib test
# Result: 16 files checked, 15 files formatted cleanly in 0.11s

# Static analysis
flutter analyze
# Result: Analyzing mobile... No issues found! (ran in 7.1s)

# Android build configuration
flutter build apk --config-only
# Result: Android Gradle and Flutter Gradle plugins resolved with exit code 0

# Web app baseline check
npm run lint && npm run build (in web/)
# Result: 0 lint errors, build succeeded in 330ms (unaltered)
```

### 2. macOS Native Linker Diagnostic
As established in Phase 0, `flutter test` on the macOS host environment encounters an Apple Command Line Tools linker issue (`MacOSX27.0.sdk` `arm64e.x1-macos` tbd parsing error in `objective_c` build hook). This is purely a host macOS compiler issue and does not impact Android build or runtime execution.

---

## 7. How to Run the Android Application

### Prerequisites
1. Have an Android device connected via USB with **USB Debugging** enabled, OR have an Android Virtual Device (AVD) running in Android Studio.
2. Start the Express backend server on port 5000:
   ```bash
   cd server
   npm start
   ```

### Running the App
From the `mobile/` directory:
```bash
cd mobile

# Run on the connected Android emulator/device
flutter run

# To specify a custom API URL (e.g. for a physical phone):
flutter run --dart-define=API_URL=http://192.168.1.50:5000/api
```

---

## 8. Learning Exercises (Phase 1)

1. **Question 1**: What is the difference between `context.go('/login')` and `context.push('/login')` in GoRouter?
2. **Question 2**: In `mobile/lib/core/widgets/app_button.dart`, why do we check `if (isLoading)` and render a `CircularProgressIndicator` instead of the button text?
3. **Question 3**: Why did we add `android:usesCleartextTraffic="true"` to `AndroidManifest.xml`?
4. **Question 4**: In `mobile/lib/core/widgets/cyber_background.dart`, why is the main content wrapped in a `SafeArea` widget?
5. **Question 5**: What does `kIsWeb` check in Flutter?

---

### Exercise Answers

- **Answer 1**: `context.push()` pushes a new screen onto the navigation stack, allowing the user to press the Android back button and return to the previous screen. `context.go()` replaces the current route stack with the new path, which is useful when transitioning after login or logout.
- **Answer 2**: When an API request is in-flight, displaying the spinner gives the user immediate visual feedback that work is happening, and disabling `onPressed` prevents duplicate form submissions.
- **Answer 3**: Starting with Android 9 (API level 28), Android blocks all unencrypted cleartext HTTP connections by default for security. Adding `android:usesCleartextTraffic="true"` allows the emulator to connect to `http://10.0.2.2:5000/api` during local development.
- **Answer 4**: `SafeArea` automatically adds padding around its child to prevent content from overlapping with device hardware intrusions, such as camera notches, status bars, and navigation gesture bars at the bottom of the screen.
- **Answer 5**: `kIsWeb` is a compile-time boolean constant in Flutter foundation that evaluates to `true` if the app is currently running in a web browser, and `false` if running on native mobile/desktop. It allows conditional platform code without crashing on missing native libraries.

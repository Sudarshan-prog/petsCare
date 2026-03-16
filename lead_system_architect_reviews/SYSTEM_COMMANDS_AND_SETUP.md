# 🏗️ Lead System Architect: Operations & Setup Manual
**Project:** PetCareBridge (carebridge)  
**Classification:** Internal Architectural Review  
**Date:** March 2, 2026

---

## 1. Environment & Project Setup
To ensure parity between development environments and the production-ready prototype, follow these steps:

### A. Flutter Environment
1. **SDK Version:** Ensure you are on Flutter `>=3.0.0`.
   ```powershell
   flutter doctor
   ```
2. **Get Dependencies:**
   ```powershell
   flutter pub get
   ```

### B. Firebase Orchestration
The app is 100% dependent on Firebase (Analytics, Auth, Firestore, Storage, Messaging).
1. **Install Firebase CLI (if not present):**
   ```powershell
   npm install -g firebase-tools
   ```
2. **Login & Initialize:**
   ```powershell
   firebase login
   flutterfire configure
   ```
3. **Deploy Rules:**
   ```powershell
   firebase deploy --only firestore:rules,storage:rules
   ```

---

## 2. Critical Commands (The Architect's Toolkit)

### Development Loop
| Action | Command | Purpose |
| :--- | :--- | :--- |
| **Clean Build** | `flutter clean; flutter pub get` | Fixes 90% of cache/plugin issues. |
| **Run (Debug)** | `flutter run` | Starts the app on connected device/emulator. |
| **Run (Release)** | `flutter run --release` | Tests performance (crucial for Haversine logic). |
| **Build APK** | `flutter build apk --split-per-abi` | Prepares for Android distribution. |
| **Generate Icons** | `dart run flutter_launcher_icons` | Updates app icons via `pubspec.yaml`. |

### Database & Auth Simulation
| Task | Instructions |
| :--- | :--- |
| **Bypass Phone Auth** | Use code `123456` on any phone number (Simulation mode active in `auth_repository.dart`). |
| **Reset Firestore** | Go to Firebase Console -> Firestore -> Data -> Delete all collections (Careful! Destructive). |

---

## 3. High-Priority Architectural Instructions

### Protocol for Feature Implementation
1. **Feature Separation:** Do NOT add new functionality directly to `HomeScreen`. Create a new folder in `features/` for every logical grouping.
2. **Model Extraction:** All new models MUST be placed in `lib/models/` or `lib/core/models/` to avoid the circular dependency issues identified in the audit.
3. **Async Guardrails:** Always use `ref.watch(provider).when(...)` in the UI. Never use `AsyncValue.asData` without safety checks.

---

## 4. Immediate Refactoring Tasks (Phase 1)
As the Lead Architect, I expect the following setup before we proceed to Phase 3:

1. **Break the "God-Widget":** Extract `_buildMyBookings` and `_buildFeaturedCaretakers` from `home_screen.dart` into separate files in `lib/features/home/presentation/widgets/`.
2. **Real AI Integration:** Generate a Gemini API Key and replace the hardcoded `Map` in `ai_service.dart`.
3. **Role Validation:** Implement a proper `AppUser` check in `main.dart` that prevents "Owner" UI from loading items from "Caretaker" collections.

---

## 5. Decision Log & Communication Protocol
*   **Default:** All instructions and reviews will be stored as reports in `/lead_system_architect_reviews/`.
*   **Bypass:** If the message "give in chat" is provided, I will respond directly in the chat interface.
*   **Verification:** After every major refactor, run `flutter build apk` to ensure no compile-time errors were introduced by dynamic typing.

---

## 6. Zero-State Resets & Data Management
The project includes a specialized script for performing a **"Nuclear Purge"** of test data. This is essential for moving from UAT (User Acceptance Testing) to live demonstrations.

### A. The Primary Method: One-Click Maintenance Tool
We have a custom script at `/scripts/maintenance_tool.js`. This script uses the **Firebase Admin SDK** to bypass the 50-document limit of the Firebase Console, performing a full wipe of both **Authentication** and **Firestore** simultaneously.

**Prerequisites:**
1.  **Service Account:** Go to Firebase Console -> Project Settings -> Service Accounts -> "Generate New Private Key".
2.  **Deployment:** Place the downloaded JSON file in `/scripts/` and rename it to `service-account.json`.
3.  **Dependencies:** `npm install firebase-admin` in the scripts directory.

**Execution:**
```powershell
# Navigate to the scripts directory
cd scripts
# Run the purge
node maintenance_tool.js
```
*   **Actionable Items:** Deletes all Auth Users, wipes `users`, `caretakers`, `pets`, and `bookings` collections.

### B. Manual Backup Methods
If the Service Account is not available, use these fallback methods:

1.  **Firebase CLI (Firestore Only):**
    ```powershell
    firebase firestore:delete --all-collections
    ```
2.  **Console Purge:**
    *   **Manual Deletion:** Manually delete `storage/profile_images` and `storage/status_photos` (as the script currently targets DB only).
    *   **Authentication:** Manually clear the User list in the Auth tab if the script is not used.

---
**End of Report**

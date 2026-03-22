# 🎯 CAREBRIDGE — PATH B MASTER IMPLEMENTATION PLAN

**Document:** Living Implementation Plan (Update as we execute)  
**Owner:** Lead System Architect  
**Approach:** Strip → Harden → Ship  
**Target:** Real bookings, real money, zero fake features  
**Timeline:** 8 Weeks to Launch-Ready

---

## THE PHILOSOPHY

```
We are NOT building a feature-rich platform.
We are building a TRUST MACHINE.

One loop. End to end. No simulation. No decoration.

Owner finds caretaker → Books → Pays REAL money → 
Caretaker accepts → Sends REAL photo → Owner finishes → 
Rates → Gets REAL notification → Money ACTUALLY moves.

If it's not part of this loop, it doesn't ship in V1.
```

---

## WHAT STAYS vs. WHAT GETS CUT

### ✅ STAYS (The Core Booking Loop)

| Feature | Why It Stays |
|---------|-------------|
| Email/Google Sign-in | Core auth — works correctly today |
| Role Selection (Owner/Caretaker) | Dual-role is a differentiator |
| Caretaker Profile Setup | Required for marketplace |
| Pet Profile Setup | Required for booking |
| Proximity-sorted Caretaker Discovery | The core value proposition |
| Booking Flow (service + pet + date + time) | The core transaction |
| Razorpay Payment (with REAL backend capture) | Money must flow |
| Caretaker Accept/Reject | Core marketplace mechanic |
| Live Photo Updates | Genuine differentiator |
| Booking Completion + Photo Purge | Lifecycle management |
| Rating System (with server validation) | Trust building |
| Push Notifications (for booking events) | Essential communication |
| Profile Screen + Edit Profile | User management |
| Booking History | Transaction record |
| Earnings Screen (with CORRECT fee math) | Caretaker motivation |
| Account Deletion | Legal requirement |
| TOS / Privacy Policy | Legal requirement |

### ❌ CUT FROM V1 (Hidden, Not Deleted)

| Feature | Why It Gets Cut | How We Handle It |
|---------|----------------|-----------------|
| AI Wellness Chat | 5-entry dictionary is deceptive | **Hide the tab entirely** — replace with Booking History tab |
| Adoption Tab | "Coming in Phase 4" placeholder | **Hide** — remove from bottom nav |
| Search Bar | Zero functionality | **Remove from HomeScreen** |
| Business Toolkit Grid | All 4 cards are static decoration | **Remove from CaretakerHomeScreen** |
| Availability Toggle | Hardcoded to true, does nothing | **Cut from V1** — add properly in Phase 4 |
| SOS Help Card | No emergency caretaker system | **Remove card from service grid** |
| Resource Center | Content exists but isn't core | **Hide** — gives caretaker bottom nav room |
| Phone Auth (simulated) | Bypass is a security hole | **Remove entirely** — email + Google is sufficient for V1 |

> [!IMPORTANT]
> **"Hidden" means we comment out the code and remove the nav item. We don't delete the files.** When we're ready for V2, we bring these features back with real implementations.

---

## CRITICAL DECISIONS LOG

Before we start coding, these business decisions need to be made:

### Decision 1: Fee Model ✏️
```
RECOMMENDATION: Hybrid Model
Formula: platformFee = max(₹15, totalPrice * 0.05)

Apply this EVERYWHERE:
  - booking_model.dart (toMap calculation)
  - Cloud Function (server-side validation)
  - earnings_screen.dart (display)
  - caretaker_home_screen.dart (revenue card)

Sudarshan: Do you agree with this model? If you prefer flat ₹15 
or straight percentage, tell me now — we'll hardcode it once.
```

### Decision 2: AI Feature Disposition ✏️
```
RECOMMENDATION: Hide for V1 launch. Bring back in V2 with 
either Gemini API integration or a proper knowledge base.

Alternative: If you want AI in V1, we integrate Google's Gemini 
API. Cost: ~$0.001 per query. Time: 3-5 additional days.

Sudarshan: Hide it or build it real? 
```

### Decision 3: Chat Feature ✏️  
```
RECOMMENDATION: Defer to post-launch. The empty chat/ directory 
stays empty for now. Owners and caretakers communicate through 
booking notes + phone (already collected in profile).

Alternative: Build real-time chat (Firestore subcollection). 
Time: 2-3 additional weeks.

Sudarshan: Defer or build?
```

---

## PHASE 0: EMERGENCY SECURITY
**Timeline:** Day 1 (3 hours)  
**Prerequisite:** Nothing — do this FIRST  
**Goal:** Stop the active security breach

### Task List

| # | Task | File/Location | Time | Command/Action |
|---|------|--------------|:----:|----------------|
| 0.1 | Remove service-account.json from Git tracking | Terminal | 5 min | `git rm --cached scripts/service-account.json` |
| 0.2 | Commit and push the removal | Terminal | 5 min | `git commit -m "security: remove leaked service account key"` |
| 0.3 | Rotate service account key in GCP Console | GCP Console → IAM → Service Accounts | 15 min | Create new key, delete old key |
| 0.4 | Restrict Google Maps API key | GCP Console → APIs → Credentials | 10 min | Add Android app restriction (package name + SHA) |
| 0.5 | Wrap phone auth in kDebugMode (interim) | `auth_repository.dart:116` | 10 min | `if (kDebugMode) { simulate } else { throw }` |
| 0.6 | Remove phone auth UI entirely from V1 | Onboarding screens | 30 min | Comment out OTP step in caretaker/pet setup |
| 0.7 | Verify [.gitignore](file:///c:/Users/Lenovo/Desktop/petCareBridge/.gitignore) covers all secrets | [.gitignore](file:///c:/Users/Lenovo/Desktop/petCareBridge/.gitignore) | 10 min | Ensure [app_config.dart](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/core/config/app_config.dart), [service-account.json](file:///c:/Users/Lenovo/Desktop/petCareBridge/scripts/service-account.json), [firebase_options.dart](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/firebase_options.dart) are listed |
| 0.8 | Enable Firebase App Check | Firebase Console | 20 min | Register app, add Play Integrity / DeviceCheck |

**Exit Criteria:** No secrets in Git, API keys restricted, phone auth disabled, App Check active.

---

## PHASE 1: BACKEND FOUNDATION
**Timeline:** Week 1-2  
**Prerequisite:** Phase 0 complete  
**Goal:** 5 Cloud Functions that make money and notifications real

### Step 1.1: Initialize Cloud Functions Project

```
Directory: petCareBridge/functions/
Runtime: Node.js 18 + TypeScript
Dependencies: firebase-admin, firebase-functions, razorpay (npm package)
```

### Step 1.2: Cloud Function #1 — [createBooking](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/features/booking/presentation/providers/booking_provider.dart#23-32)
**Trigger:** `functions.https.onCall`  
**What it does:**
1. Receives: caretakerId, petId, services[], hours, date, timeSlot
2. **Fetches caretaker's ACTUAL price** from Firestore (not from client)
3. Calculates: `basePrice + servicePremiums + platformFee` server-side
4. Checks for booking overlap (same caretaker, same date, same timeslot)
5. Creates booking document with server-calculated values
6. Returns booking ID to client

**Why this matters:** Client can no longer write `totalPrice: 0`. Server controls all financial data.

### Step 1.3: Cloud Function #2 — [updateBookingStatus](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/features/booking/presentation/providers/booking_provider.dart#33-81)
**Trigger:** `functions.https.onCall`  
**What it does:**
1. Receives: bookingId, newStatus
2. **Validates state transition** (state machine):
   ```
   pending   → confirmed  (caretaker only)
   pending   → cancelled  (either party)
   confirmed → completed  (owner only)
   confirmed → cancelled  (either party, with refund)
   ```
3. **Handles payment operations:**
   - `pending → confirmed`: Razorpay `payments.capture()` with API secret
   - `pending → cancelled`: Razorpay release (auto-expires, or void API call)
   - `confirmed → cancelled`: Razorpay `payments.refund()`
4. Updates booking status AND payment status atomically
5. **Sends FCM push notification** to the other party:
   - Owner confirms → caretaker gets "New booking request!"
   - Caretaker accepts → owner gets "Your booking was accepted!"
   - Booking completed → caretaker gets "You've been rated ⭐"

**Why this matters:** Status transitions enforced server-side. Real money captured and refunded. Notifications actually sent.

### Step 1.4: Cloud Function #3 — `submitRating`
**Trigger:** `functions.https.onCall`  
**What it does:**
1. Receives: bookingId, rating (number)
2. Validates: rating is between 1.0 and 5.0
3. Validates: caller is the owner of this booking
4. Validates: booking status is 'completed'
5. Validates: this booking hasn't been rated before (check `isRated` field)
6. Runs Firestore transaction to update caretaker's running average
7. Marks booking as `isRated: true`

**Why this matters:** Eliminates rating manipulation. Can't rate without completing a booking. Can't rate twice.

### Step 1.5: Cloud Function #4 — `deleteAccount`
**Trigger:** `functions.https.onCall`  
**What it does:**
1. Validates caller is the authenticated user
2. Deletes all user's pets from `pets` collection
3. Cancels all pending bookings (with payment release)
4. Deletes user document from `users` collection
5. Deletes caretaker document (if exists) from `caretakers` collection
6. Deletes profile photo from Storage
7. Deletes Firebase Auth account

**Why this matters:** Legal requirement for App Store and Play Store compliance.

### Step 1.6: Cloud Function #5 — Razorpay Webhook
**Trigger:** `functions.https.onRequest` (HTTP endpoint)  
**What it does:**
1. Receives Razorpay webhook events
2. Validates webhook signature (using Razorpay webhook secret)
3. On `payment.authorized` → Update booking `paymentStatus` to 'authorized'
4. On `payment.captured` → Update booking `paymentStatus` to 'paid'  
5. On `payment.failed` → Update booking `paymentStatus` to 'failed', set status to 'cancelled'
6. On `refund.processed` → Update booking `paymentStatus` to 'refunded'

**Why this matters:** Server-side confirmation of payment events. Client callbacks are unreliable.

### Step 1.7: Rewrite Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // USERS: Only the user can read/write their own document
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId
        && request.resource.data.diff(resource.data)
           .affectedKeys()
           .hasOnly(['name', 'phoneNumber', 'latitude', 'longitude', 
                     'profileUrl', 'fcmToken', 'lastTokenUpdate']);
      allow delete: if false; // Only via Cloud Function
    }
    
    // CARETAKERS: Read by anyone auth'd, write only by owner
    match /caretakers/{caretakerId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == caretakerId;
      allow update: if request.auth.uid == caretakerId
        && request.resource.data.diff(resource.data)
           .affectedKeys()
           .hasOnly(['name', 'bio', 'specialties', 'price', 
                     'phoneNumber', 'latitude', 'longitude',
                     'profileUrl', 'serviceFees', 'isAvailable']);
      // rating, reviewCount, isVerified: ONLY via Cloud Function
      allow delete: if false;
    }
    
    // BOOKINGS: Created only by Cloud Function, limited field updates
    match /bookings/{bookingId} {
      allow read: if request.auth != null 
        && (request.auth.uid == resource.data.ownerId 
            || request.auth.uid == resource.data.caretakerId);
      allow create: if false; // Only via Cloud Function
      allow update: if false; // Only via Cloud Function
      allow delete: if false;
    }
    
    // PETS: Owner manages their own
    match /pets/{petId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null 
        && request.resource.data.ownerId == request.auth.uid;
      allow update: if request.auth != null 
        && resource.data.ownerId == request.auth.uid;
      allow delete: if request.auth != null 
        && resource.data.ownerId == request.auth.uid;
    }
  }
}
```

**Key change:** Bookings are now created and updated ONLY by Cloud Functions. The client cannot touch financial data or status fields directly.

**Exit Criteria:** All 5 Cloud Functions deployed. Razorpay test payments flowing end-to-end. Push notifications received on device. Firestore rules tested.

---

## PHASE 2: SURGICAL CLIENT CLEANUP
**Timeline:** Week 2-3 (overlaps with Phase 1 testing)  
**Prerequisite:** Cloud Functions deployed  
**Goal:** Client calls backend instead of writing directly. Non-functional UI removed.

### Step 2.1: Strip Non-Functional Features from UI

| File | What to Remove/Hide | How |
|------|---------------------|-----|
| [main_layout.dart](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/shared/widgets/main_layout.dart) | Remove adoption tab (index 1) and AI/Resource tab (index 2) | Change from 4 tabs to 3: Home, History, Profile |
| [home_screen.dart](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/features/home/presentation/pages/home_screen.dart) | Remove search bar (lines 121-142) | Delete [_buildSearchBar](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/features/home/presentation/pages/home_screen.dart#121-144) call and method |
| [home_screen.dart](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/features/home/presentation/pages/home_screen.dart) | Remove SOS Help card from service grid | Remove from [_buildServiceGrid](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/features/home/presentation/pages/home_screen.dart#552-585) |
| [home_screen.dart](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/features/home/presentation/pages/home_screen.dart) | Remove AI Wellness card from service grid | Remove from [_buildServiceGrid](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/features/home/presentation/pages/home_screen.dart#552-585) |
| [caretaker_home_screen.dart](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/features/home/presentation/pages/caretaker_home_screen.dart) | Remove Business Toolkit grid (lines 479-506) | Delete [_buildToolGrid](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/features/home/presentation/pages/caretaker_home_screen.dart#479-508) call and method |
| [caretaker_home_screen.dart](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/features/home/presentation/pages/caretaker_home_screen.dart) | Remove Status Toggle (lines 166-198) | Delete [_buildStatusToggle](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/features/home/presentation/pages/caretaker_home_screen.dart#166-200) call and method |
| [main_layout.dart](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/shared/widgets/main_layout.dart) | Remove "Coming soon in Phase 4" placeholder | Delete [_buildPlaceholderPage](file:///c:/Users/Lenovo/Desktop/petCareBridge/lib/shared/widgets/main_layout.dart#38-74) method |

### Step 2.2: Replace Client-Side Booking with Cloud Function Call

**Before (booking_screen.dart):**
```dart
// Client calculates price and writes to Firestore
final total = basePrice + totalPremiums + platformFee;
await ref.read(bookingProvider.notifier).createBooking(Booking(...totalPrice: total...));
```

**After:**
```dart
// Client sends intent, server calculates price
final result = await FirebaseFunctions.instance.httpsCallable('createBooking').call({
  'caretakerId': widget.caretaker.id,
  'petId': selectedPet.id,
  'services': _selectedServices,
  'hours': _selectedHours,
  'date': _selectedDate.toIso8601String(),
  'timeSlot': _selectedTimeSlot,
  'notes': _notesController.text,
});
// Server returns the booking with server-calculated price
```

### Step 2.3: Replace Simulated Payment Operations

**Before (razorpay_repository.dart):**
```dart
Future<void> capturePayment(String paymentId, double amount) async {
  debugPrint('Capturing...');  // FAKE
  await Future.delayed(Duration(seconds: 1));
}
```

**After:**
```dart
Future<void> capturePayment(String paymentId, double amount) async {
  // Payment capture now happens in Cloud Function when status changes
  // This method is no longer called from client
  throw UnimplementedError('Payment operations moved to server');
}
```

### Step 2.4: Replace Client Status Updates with Cloud Function Calls

**Before (booking_provider.dart):**
```dart
await _repository.updateBookingStatus(bookingId, status);
await _paymentRepository.capturePayment(booking.paymentId!, booking.totalPrice);
```

**After:**
```dart
await FirebaseFunctions.instance.httpsCallable('updateBookingStatus').call({
  'bookingId': bookingId,
  'newStatus': status,
});
// Server handles: status validation + payment capture + notification sending
```

### Step 2.5: Fix Fee Model

Pick ONE formula and apply everywhere:
```dart
// In Cloud Function (single source of truth):
const platformFee = Math.max(15, totalPrice * 0.05);
const caretakerPayout = totalPrice - platformFee;

// In Dart models (for display only — NOT for calculation):
// Booking model receives these values FROM the server
```

### Step 2.6: Add Dart Enums for Status Fields

```dart
// lib/models/booking_status.dart
enum BookingStatus {
  pending, confirmed, completed, cancelled;
  
  static BookingStatus fromString(String s) =>
    BookingStatus.values.firstWhere((e) => e.name == s, 
      orElse: () => BookingStatus.pending);
}

enum PaymentStatus {
  unpaid, authorized, paid, released, refunded, failed;
  
  static PaymentStatus fromString(String s) =>
    PaymentStatus.values.firstWhere((e) => e.name == s,
      orElse: () => PaymentStatus.unpaid);
}
```

### Step 2.7: Add Error Handling to ALL Repository Methods

```dart
// Pattern for every repository method:
Future<void> someOperation() async {
  try {
    await _firestore.collection('x').doc('y').update({...});
  } on FirebaseException catch (e) {
    throw AppException('Failed to update: ${e.message}', code: e.code);
  } catch (e) {
    throw AppException('Unexpected error: $e');
  }
}
```

### Step 2.8: Fix TextEditingController Memory Leak

```dart
// booking_screen.dart — Add dispose override
@override
void dispose() {
  _notesController.dispose();
  super.dispose();
}
```

**Exit Criteria:** App makes zero direct Firestore writes for bookings/status/ratings. All fake code removed. Non-functional UI elements hidden. Enums for all status types. Error handling in every repository.

---

## PHASE 3: ARCHITECTURE CLEANUP
**Timeline:** Week 3-4  
**Prerequisite:** Phase 2 complete  
**Goal:** Code is organized, maintainable, and ready for team growth

### Step 3.1: Extract Models to `lib/models/`

```
lib/models/
├── app_user.dart         (from auth_provider.dart:13-73)
├── caretaker.dart        (from caretaker_provider.dart:7-77)
├── pet.dart              (from pet_provider.dart:5-43)
├── booking.dart          (from booking/data/models/booking_model.dart — move here)
├── booking_status.dart   (new — enums)
├── payment_state.dart    (from payment_provider.dart:10-35)
└── auth_state.dart       (from auth_provider.dart:76-94)
```

### Step 3.2: Split AuthNotifier (343 lines → 3 focused classes)

```
lib/core/auth/
├── auth_notifier.dart         (login, signup, OAuth, logout — ~80 lines)
├── user_profile_notifier.dart (updateProfile, updateLocation — ~60 lines)
└── onboarding_notifier.dart   (saveUserRole, savePetProfile, saveCaretakerProfile — ~80 lines)
```

### Step 3.3: Split Mega-Screens into Widgets

```
lib/features/home/presentation/
├── pages/
│   ├── home_screen.dart              (was 782 lines → ~150 lines)
│   └── caretaker_home_screen.dart    (was 530 lines → ~120 lines)
└── widgets/
    ├── owner_booking_card.dart       (extracted from home_screen)
    ├── caretaker_list_item.dart      (extracted from home_screen)
    ├── service_grid.dart             (extracted from home_screen)
    ├── header_bar.dart               (shared between both home screens)
    ├── earnings_card.dart            (extracted from caretaker_home_screen)
    ├── booking_request_card.dart     (extracted from caretaker_home_screen)
    └── photo_update_button.dart      (extracted from caretaker_home_screen)

lib/features/booking/presentation/
├── pages/
│   └── booking_screen.dart           (was 658 lines → ~200 lines)
└── widgets/
    ├── service_selector.dart
    ├── pet_selector.dart
    ├── datetime_picker.dart
    └── price_summary_bar.dart
```

### Step 3.4: Add GoRouter for Declarative Navigation

```dart
// lib/core/router/app_router.dart
final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) { /* auth check */ },
  routes: [
    GoRoute(path: '/', builder: (_, __) => MainLayout()),
    GoRoute(path: '/onboarding/role', builder: (_, __) => RoleSelectionScreen()),
    GoRoute(path: '/onboarding/pet', builder: (_, __) => PetProfileSetupScreen()),
    GoRoute(path: '/onboarding/caretaker', builder: (_, __) => CaretakerSetupScreen()),
    GoRoute(path: '/booking/:caretakerId', builder: (_, state) => BookingScreen(
      caretakerId: state.pathParameters['caretakerId']!,
    )),
    GoRoute(path: '/booking/history', builder: (_, __) => BookingHistoryScreen()),
    GoRoute(path: '/profile/edit', builder: (_, __) => EditProfileScreen()),
    GoRoute(path: '/profile/earnings', builder: (_, __) => EarningsScreen()),
    GoRoute(path: '/profile/pets', builder: (_, __) => MyPetsScreen()),
  ],
);
```

**Why:** enables deep linking from push notifications (tap notification → go directly to booking).

### Step 3.5: Add Pagination to Caretaker List

```dart
// caretaker_repository.dart — Before:
Stream<List<Caretaker>> get caretakersStream {
  return _firestore.collection('caretakers').snapshots()...  // ALL docs
}

// After:
Stream<List<Caretaker>> caretakersStream({int limit = 20}) {
  return _firestore.collection('caretakers')
    .orderBy('rating', descending: true)
    .limit(limit)
    .snapshots()...
}
```

**Exit Criteria:** No file over 250 lines. Models independent of providers. Named routes everywhere. Pagination on all lists.

---

## PHASE 4: ESSENTIAL FEATURES
**Timeline:** Week 5-6  
**Prerequisite:** Phase 3 complete  
**Goal:** Fill the minimum feature gaps for a usable product

| # | Feature | Scope | Time |
|---|---------|-------|:----:|
| 4.1 | **Account Deletion flow** — Profile → Delete Account → Confirm → Call Cloud Function | UI + Cloud Function (already built in Phase 1) | 1 day |
| 4.2 | **TOS / Privacy Policy screen** — Show on first login, track acceptance in Firestore | New screen + Firestore field | 1 day |
| 4.3 | **Booking overlap detection** — Cloud Function checks for conflicts before creating | Already in Cloud Function from Phase 1 | Included |
| 4.4 | **Caretaker search** — Add `onChanged` to search bar, filter by name/specialty | Hook up to existing text field (re-add search bar once it works) | 2 days |
| 4.5 | **Availability toggle** — Add `isAvailable` field, wire toggle, filter in discovery | Caretaker model + Firestore + UI | 1 day |
| 4.6 | **Add Firestore composite indexes** | `firestore.indexes.json` | 2 hours |
| 4.7 | **Fix MainLayout to use IndexedStack** — preserve tab state | `main_layout.dart` | 1 hour |
| 4.8 | **Add global error handler** — `runZonedGuarded` + `FlutterError.onError` | `main.dart` | 2 hours |

**Exit Criteria:** Users can delete accounts. TOS accepted. No double-bookings. Search works. Caretakers can go offline.

---

## PHASE 5: TESTING & LAUNCH PREP
**Timeline:** Week 7-8  
**Prerequisite:** Phase 4 complete  
**Goal:** Confidence to ship + visibility into production

### Testing Strategy

| Layer | What We Test | Tool |
|-------|-------------|------|
| **Unit Tests** | All notifiers (auth, booking, payment) + all repository methods | `flutter_test` + `mocktail` |
| **Cloud Function Tests** | All 5 functions with mock Firestore/Razorpay | `jest` + `firebase-functions-test` |
| **Widget Tests** | Booking card, rating dialog, service selector | `flutter_test` |
| **Integration Tests** | Full auth → book → pay → accept → complete flow | `integration_test` + Firebase Emulator Suite |

### Observability Setup

| Tool | Purpose | Time |
|------|---------|:----:|
| Firebase Crashlytics | Crash reports + non-fatal errors | 2 hours |
| Firebase Analytics | Screen views, booking funnel, completion rate | 3 hours |
| Firebase Performance | Network request latency, app startup time | 1 hour |

### Launch Checklist

```
□ All simulated code removed or behind kDebugMode
□ Real Razorpay live key configured (via --dart-define)
□ Firebase App Check enforced (not just monitoring)
□ All 5 Cloud Functions deployed to production
□ Firestore rules deployed
□ Storage rules deployed
□ Composite indexes deployed
□ Crashlytics receiving test crash
□ Analytics receiving test events
□ Push notifications working end-to-end
□ Account deletion working
□ TOS/Privacy Policy displayed and tracked
□ App signed with release keystore
□ Play Store listing prepared
□ Privacy Policy URL set in Play Console
```

**Exit Criteria:** 80%+ test coverage on business logic. Crashlytics + Analytics active. Launch checklist complete.

---

## THE TIMELINE — VISUAL

```
        MARCH                          APRIL                           MAY
Week:   W1          W2          W3          W4          W5          W6          W7          W8
        ┌───────────┬───────────┬───────────┬───────────┬───────────┬───────────┬───────────┬───────────┐
Phase 0 │██ DAY 1   │           │           │           │           │           │           │           │
        │ Security  │           │           │           │           │           │           │           │
        ├───────────┼───────────┤           │           │           │           │           │           │
Phase 1 │ Cloud Fn  │ Cloud Fn  │           │           │           │           │           │           │
        │ Setup+3fn │ 2fn+Rules │           │           │           │           │           │           │
        │           ├───────────┼───────────┤           │           │           │           │           │
Phase 2 │           │ Strip UI  │ Client    │           │           │           │           │           │
        │           │ Remove    │ → Server  │           │           │           │           │           │
        │           │           ├───────────┼───────────┤           │           │           │           │
Phase 3 │           │           │ Models    │ Widgets   │           │           │           │           │
        │           │           │ Refactor  │ Router    │           │           │           │           │
        │           │           │           │           ├───────────┼───────────┤           │           │
Phase 4 │           │           │           │           │ Search    │ Toggle    │           │           │
        │           │           │           │           │ TOS+Del   │ Indexes   │           │           │
        │           │           │           │           │           │           ├───────────┼───────────┤
Phase 5 │           │           │           │           │           │           │ Tests     │ Launch    │
        │           │           │           │           │           │           │ Crashlytx │ Prep      │
        └───────────┴───────────┴───────────┴───────────┴───────────┴───────────┴───────────┴───────────┘
                                                                                            
                    ▲                       ▲                                   ▲
                    │                       │                                   │
              ALPHA MILESTONE         BETA MILESTONE                     LAUNCH READY
              "Real money flows"  "50 users can test"               "Play Store submit"
```

---

## HOW WE WORK TOGETHER

Here's how I propose we operate:

### Daily Approach
1. **I build. You review.** I'll implement each task and explain what I'm doing and why.
2. **One phase at a time.** We don't start Phase 2 until Phase 1 is tested and working.
3. **You make business decisions. I make technical decisions.** Fee model, feature scope = you. Code architecture, security = me.

### When You Should Push Back
- If I'm cutting a feature you believe is essential for launch
- If the timeline feels too aggressive or too conservative
- If a business decision needs context I don't have

### When I'll Push Back
- If a feature request threatens timeline without proportional user value
- If a "quick fix" creates technical debt that slows us down later
- If security is being deprioritized for speed

---

## IMMEDIATE NEXT STEP

**Phase 0 is a 3-hour sprint.** I can execute it right now. It requires:

1. Terminal commands to remove the service account key from Git
2. Code changes to disable phone auth simulation in production
3. Removing/commenting out OTP UI elements
4. Updating `.gitignore` to be airtight

**After Phase 0, we start Phase 1: Cloud Functions.** I'll need you to confirm:
- [ ] Fee model decision (hybrid ₹15/5%, flat ₹15, or flat %)
- [ ] AI feature decision (hide or build real)
- [ ] Chat decision (defer or build)

---

*This plan is a living document. We'll update it as we execute. Every crossed-off task is one step closer to real users, real money, and a real product.*

**— Your Lead System Architect**  
**March 16, 2026**

# CareBridge: Developer Specification & Blueprint
**Version:** 1.0 (Production-Ready Prototype)
**Target Platforms:** Android (Kotlin) & iOS (Swift) via Flutter/React Native

## 1. Executive Summary
CareBridge is a dual-service ecosystem connecting **Pet Owners** with **Verified Caretakers** and **Adoption Hubs**. The core value proposition is **Tiered Trust Verification** and **Proximity-based Service Matching**.

---

## 2. Technical Architecture (Backend Foundation)
The current web prototype runs on Node.js + MongoDB Atlas. A mobile developer must replicate/integrate these endpoints:

### A. Data Models (REST API)
| Entity | Key Attributes |
| :--- | :--- |
| **User** | Name, Email (Unique), Hashed Password (Bcrypt), CreatedAt |
| **Caretaker** | Name, Bio, Rate (₹), Location (GeoJSON), `verificationTier` (Pro/Trusted/Verified), `isIdVerified`, `isBackgroundChecked`, `isPartnerEndorsed`, `partnerName`, `isEmergency` (Boolean) |
| **Booking** | `serviceType` (Pet/Caretaking), `status` (Pending/Accepted/Rejected), `caretakerId`, `videoCall` (Boolean), `includeEduHealth` (Boolean), Notes |
| **Pet** | Name, Breed, Status (Available/Adopted/Foster), Tags (e.g., "Active", "Vaccinated") |

### B. Core APIs to Implement
1.  `GET /api/caretakers?search=...&emergency=1`: Proximity/Search filtered list.
2.  `POST /api/bookings`: Triggers notification flow for caretakers.
3.  `POST /api/chat`: Dual-logic AI endpoint (Checks `knowledge-base.json` locally; falls back to Gemini API).
4.  `PATCH /api/bookings/:id/status`: Real-time status sync between Owner and Caretaker.

---

## 3. High-Priority Feature Matrix

### 1. Trusted Verification System (The "Trust Anchor")
*   **Attributes**: 
    - `Verified Badge`: Green check icon.
    - `Trust Modal`: Pop-up checklist showing ID scan status, Background check status, and NGO endorsement name.
*   **Logic**: Caretakers cannot access "Pro" status without `isIdVerified = true`.
*   **Value**: Establishes credibility for high-value services.

### 2. Intelligent Booking Engine
*   **GPS Logic**: App must calculate Haversine distance from `UserLocation` to `CaretakerLocation`.
*   **Booking UI**: Must support date/time selection with a "Caretaker Selection" swipe-list.
*   **Education Hub**: A checkbox in the booking flow that attaches nutritional/health data to the request.

### 3. Emergency SOS System
*   **Primary Action**: Immediate access to on-call caretakers (`isEmergency: true`).
*   **Video Integration**: Jitsi Meet integration. Mobile app should launch a Webview or Deep Link to a direct meet room using `BookingID` as the `RoomName`.

### 4. AI Care Assistant (RAG)
*   **Input**: Natural language pet queries.
*   **Logic**:
    1.  Parse local `knowledge-base.json` for keywords.
    2.  If confidence < 80%, send to Gemini API with context: *"You are CareBridge AI, act according to pet wellness standards."*

---

## 4. Mobile UX Path (User Journey)

### Owner (Pet Parent) Flow
1.  **Splash/Auth**: Clean, pet-friendly UI.
2.  **Home (Dashboard)**: Swipeable cards for "Caretaking", "Adoption", and "Emergency".
3.  **Discovery**: Map-view showing nearby verified caretakers.
4.  **Booking**: 3-step checkout (Service -> Caretaker -> Confirm).
5.  **Profile**: List of active/past appointments with "Acceptance" tracking.

### Caretaker Flow
1.  **Dashboard**: Stats on earnings history and pending requests.
2.  **Request Handling**: Push notifications for new bookings.
3.  **Trust Dashboard**: Upload ID/Certifications to upgrade `verificationTier`.

---

## 5. Implementation Roadmap (Flutter/Kotlin)
### Phase 1: Core MVP (Weeks 1-2)
*   Firebase/Auth implementation.
*   MongoDB Atlas integration for the Caretaker/Pet lists.
*   Google Maps API for proximity calculation.

### Phase 2: Professional Polish (Weeks 3-4)
*   Tiered badge logic and Checkmark UI.
*   Jitsi Video wrapper.
*   Gemini API chat integration.

### Phase 3: Launch (Week 5)
*   Push Notification system for Booking Status updates.
*   Adoption inquiry flow integration.

---

## 6. Performance & UX Standards
- **Currency Support**: Fixed to **INR (₹)** as per project localization.
- **Speed**: Haversine calculations must happen client-side or via Mongo `$near` query for < 200ms results.
- **Aesthetics**: Glassmorphism and smooth transitions as established in the current `nav.js` and `style.css`.

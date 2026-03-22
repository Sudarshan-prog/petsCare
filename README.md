<div align="center">

# 🐾 CareBridge

### A Dual-Service Ecosystem for Pet Owners, Verified Caretakers & Adoption Hubs

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Razorpay](https://img.shields.io/badge/Payments-Razorpay-0C6EBA?logo=razorpay)](https://razorpay.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)](https://flutter.dev)
[![Version](https://img.shields.io/badge/Version-1.0.0-blue)](https://github.com)

> **CareBridge** connects Pet Owners with Verified Caretakers and Adoption Hubs through a single, trust-first mobile platform.

</div>

---

## 📖 Table of Contents

- [About](#-about)
- [Key Features](#-key-features)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Firebase Setup](#-firebase-setup)
- [Screenshots](#-screenshots)
- [Architecture](#-architecture)
- [Roadmap](#-roadmap)

---

## 🌟 About

India's pet care market is growing at 14% CAGR, yet pet owners have no reliable, trust-verified way to find nearby caretakers — especially in emergencies. CareBridge solves this with:

- ✅ **Tiered Trust Verification** — Caretakers earn badges via ID checks, background verifications & NGO endorsements
- 📍 **Proximity Matching** — GPS-based Haversine distance surfaces nearest caretakers in real-time
- 🚨 **Emergency SOS** — Instant access to on-call caretakers within minutes of a crisis
- 🤖 **AI Care Assistant** — RAG-powered chat (local knowledge base + Google Gemini fallback)
- 🐶 **Adoption Hub** — Browse adoptable pets from partner NGOs and shelters
- 💳 **Secure Payments** — Razorpay manual-capture flow (authorize → capture on accept / void on reject)

---

## 🚀 Key Features

| Feature | Description |
|---|---|
| 🛡️ **Trust Verification** | 3-tier system: Verified → Trusted → Pro with visual badges and Trust Modal |
| 📍 **GPS Matching** | Real-time map view showing nearby caretakers sorted by Haversine distance |
| 📅 **Smart Booking** | 3-step checkout: Service → Caretaker → Confirm + Payment |
| 🚨 **Emergency SOS** | One-tap access to `isEmergency: true` caretakers only |
| 🤖 **AI Wellness Chat** | Local RAG with Gemini API fallback for pet health queries |
| 🔔 **Push Notifications** | FCM-powered real-time alerts for all booking status changes |
| 💳 **Razorpay Payments** | INR payments with manual capture, Route API caretaker payouts |
| ⭐ **Ratings System** | Running average rating with atomic Firestore transactions |

---

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.x** (Dart) — Cross-platform mobile
- **Riverpod 2.4.9** — State management
- **Google Maps Flutter** — Proximity map view
- **Glassmorphism UI** — Premium design system
- **Google Fonts** (Inter) — Typography

### Backend & Cloud
- **Firebase Authentication** — Email/Password + Google Sign-In
- **Cloud Firestore** — Real-time NoSQL database
- **Firebase Storage** — Profile & booking images
- **Firebase Cloud Messaging** — Push notifications
- **Firebase Cloud Functions** — Server-side payment logic

### Payments & External APIs
- **Razorpay Flutter SDK** — Payment processing (INR)
- **Google Gemini API** — AI care assistant fallback
- **Google Maps Platform** — Geolocation & maps

---

## 📁 Project Structure

```
carebridge/
├── lib/
│   ├── main.dart                    # App entry point, Firebase init
│   ├── core/
│   │   ├── app_theme.dart           # Design system & theme tokens
│   │   ├── auth/                    # Auth state & providers
│   │   ├── providers/               # Global Riverpod providers
│   │   ├── repositories/            # Data layer (Firestore, Razorpay, Storage)
│   │   └── services/                # Notification service
│   ├── features/
│   │   ├── auth/                    # Login, Signup, Landing screens
│   │   ├── onboarding/              # Role selection (Owner / Caretaker)
│   │   ├── home/                    # Dashboard with swipeable cards
│   │   ├── booking/                 # 3-step booking flow + payment
│   │   ├── profile/                 # User profile & appointment history
│   │   ├── wellness/                # AI Care Assistant
│   │   └── resources/               # Pet care educational content
│   └── shared/
│       └── widgets/                 # Shared UI components
├── firestore.rules                  # Firestore security rules
├── storage.rules                    # Firebase Storage rules
├── firebase.json                    # Firebase configuration
└── pubspec.yaml                     # Dependencies
```

---

## ⚙️ Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0 <4.0.0`
- Dart SDK
- Android Studio / VS Code
- Firebase project (see [Firebase Setup](#-firebase-setup))

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/carebridge.git
cd carebridge

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

---

## 🔥 Firebase Setup

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** → Email/Password + Google
3. Create a **Firestore** database in production mode
4. Enable **Firebase Storage**
5. Enable **Firebase Cloud Messaging**
6. Download `google-services.json` → place in `android/app/`
7. Download `GoogleService-Info.plist` → place in `ios/Runner/`
8. Run: `flutterfire configure`

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│         Flutter UI Layer (Material 3 + Glassmorphism)│
├─────────────────────────────────────────────────────┤
│       State Management Layer (Flutter Riverpod)      │
├─────────────────────────────────────────────────────┤
│  Firebase Services (Auth · Firestore · FCM · Storage)│
├─────────────────────────────────────────────────────┤
│          Cloud Firestore (NoSQL) + Firebase CDN      │
└─────────────────────────────────────────────────────┘
```

**Pattern:** Feature-First Clean Architecture — each feature (`auth`, `booking`, `home`, etc.) contains its own `data`, `domain`, and `presentation` layers, communicating via Riverpod providers.

---

## 📊 Database Collections

| Collection | Key Fields |
|---|---|
| `/users` | name, email, role, latitude, longitude, fcmToken |
| `/caretakers` | name, bio, price, verificationTier, isEmergency, rating, reviewCount |
| `/bookings` | ownerId, caretakerId, status, paymentStatus, isRated |
| `/pets` | name, breed, ownerId, status (Available/Adopted/Foster), tags |

---

## 🗺️ Roadmap

- [x] **Phase 1** — Firebase Auth, Firestore data models, Google Maps, basic booking
- [x] **Phase 2** — Trust badge UI, Razorpay payments, Gemini AI chat, Emergency SOS
- [ ] **Phase 3** — Push notifications, Adoption inquiry flow, Play Store / App Store launch

---

## 📄 License

This project is built as a hackathon/competition submission.  
© 2026 CareBridge. All rights reserved.

---

<div align="center">
  <strong>🐾 CareBridge — Where Every Pet Finds Safe Hands</strong><br/>
  Built with Flutter · Powered by Firebase · Verified by Trust & Technology
</div>

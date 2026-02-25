# CareBridge - Pet Care Ecosystem

## 🏗️ Technical Architecture (v2.0)
As of Feb 2026, the app has been refactored for professional scalability:
- **Repository Pattern**: All Firebase logic is abstracted behind `IRepository` interfaces (Auth, Booking, Caretaker, Pet).
- **Type-Safety**: Financial data (prices, ratings) are enforced as `double` types to prevent runtime parsing crashes.
- **Provider-Based Logic**: Proximity calculations and data streams are managed via optimized Riverpod providers.
- **Security Logic**: Role-based access control and Firestore Security Rules are now blueprint-ready.

## Features
- **Smart Proximity**: Find verified caretakers near your current location.
- **Real-time Status**: Live acceptance/rejection of bookings.
- **Wellness Assistant**: (Phase 4) AI-driven pet health logs.
- **Care Manager**: Comprehensive pet profile management.

## Getting Started
1. Run `flutter pub get`
2. Ensure Firebase is connected
3. Run `flutter run`

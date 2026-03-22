import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/features/auth/presentation/pages/login_screen.dart';
import 'package:carebridge/features/auth/presentation/pages/signup_screen.dart';
import 'package:carebridge/features/auth/presentation/pages/landing_screen.dart';
import 'package:carebridge/features/onboarding/presentation/pages/role_selection_screen.dart';
import 'package:carebridge/shared/widgets/main_layout.dart';
import 'package:carebridge/core/providers/app_state_provider.dart';
import 'firebase_options.dart';
import 'package:carebridge/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'dart:async';

void main() async {
  // PHASE 0: Global error safety net — catches ALL unhandled exceptions
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Catch Flutter framework errors (render, layout, gesture)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('🔴 FLUTTER ERROR: ${details.exceptionAsString()}');
      // TODO Phase 5: Send to Firebase Crashlytics
      // FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // Firebase already initialized by google-services.json (Android auto-init)
      debugPrint('ℹ️ Firebase already initialized: $e');
    }

    // Initialize Notifications
    FirebaseMessaging.onBackgroundMessage(
        NotificationService.firebaseMessagingBackgroundHandler);
    await NotificationService.initialize();

    runApp(
      const ProviderScope(
        child: CareBridgeApp(),
      ),
    );
  }, (error, stackTrace) {
    // Catch async errors that escape all try-catch blocks
    debugPrint('🔴 UNHANDLED ASYNC ERROR: $error');
    debugPrint('Stack trace: $stackTrace');
    // TODO Phase 5: Send to Firebase Crashlytics
    // FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
  });
}

class CareBridgeApp extends ConsumerWidget {
  const CareBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final appState = ref.watch(appStateProvider);

    if (!appState.isInitialized || authState is AuthInitial) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    Widget getHome() {
      if (authState is AuthAuthenticated) {
        if (authState.user.role == null) {
          return const RoleSelectionScreen();
        }
        return const MainLayout();
      }

      // If not logged in, always start at the Landing (Welcome) Screen
      return const LandingScreen();
    }

    return MaterialApp(
      title: 'CareBridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: getHome(),
    );
  }
}

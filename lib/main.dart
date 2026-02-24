import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/features/auth/presentation/pages/landing_screen.dart';
import 'package:carebridge/features/onboarding/presentation/pages/role_selection_screen.dart';
import 'package:carebridge/shared/widgets/main_layout.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: CareBridgeApp(),
    ),
  );
}

class CareBridgeApp extends ConsumerWidget {
  const CareBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    Widget getHome() {
      if (authState is AuthAuthenticated) {
        if (authState.user.role == null) {
          return const RoleSelectionScreen();
        }
        return const MainLayout();
      }
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

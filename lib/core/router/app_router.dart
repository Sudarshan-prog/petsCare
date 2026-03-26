import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/shared/widgets/main_layout.dart';
import 'package:carebridge/features/onboarding/presentation/pages/role_selection_screen.dart';
import 'package:carebridge/features/onboarding/presentation/pages/pet_profile_setup_screen.dart';
import 'package:carebridge/features/onboarding/presentation/pages/caretaker_setup_screen.dart';
import 'package:carebridge/features/booking/presentation/pages/booking_screen.dart';

import 'package:carebridge/core/providers/caretaker_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Basic protection for unauthenticated routes can be handled manually if needed 
      // or here for top-level. For V1 we let individual screens handle deep auth 
      // flows if they want, or we can check here.
      if (authState is AuthUnauthenticated) {
        // We aren't implementing a full LoginScreen route redirection in V1 
        // because the AuthWrapper/MainRoot handles the login/signup swap.
        // But we could redirect to login if we had a dedicated /login route.
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainLayout(),
      ),
      GoRoute(
        path: '/onboarding/role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/pet',
        builder: (context, state) => const PetProfileSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding/caretaker',
        builder: (context, state) => const CaretakerSetupScreen(),
      ),
      GoRoute(
        path: '/booking/:caretakerId',
        builder: (context, state) {
          final id = state.pathParameters['caretakerId']!;
          // GoRouter needs to pass the Caretaker object safely if expected,
          // but our BookingScreen currently requires a Caretaker object outright.
          // In a true deep-linked app, we fetch it by ID. 
          // Since the plan emphasizes simple GoRouter, we might need a wrapper.
          return BookingRouteWrapper(caretakerId: id);
        },
      ),
    ],
  );
});

// A wrapper to handle deep-linked booking requests when we only have the ID
class BookingRouteWrapper extends ConsumerWidget {
  final String caretakerId;
  const BookingRouteWrapper({super.key, required this.caretakerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caretakerAsync = ref.watch(singleCaretakerProvider(caretakerId));

    return caretakerAsync.when(
      data: (caretaker) {
        if (caretaker == null) {
          return const Scaffold(body: Center(child: Text('Caretaker not found')));
        }
        return BookingScreen(caretaker: caretaker);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/features/home/presentation/pages/home_screen.dart';
import 'package:carebridge/features/home/presentation/pages/caretaker_home_screen.dart';
import 'package:carebridge/features/auth/presentation/pages/landing_screen.dart';
import 'package:carebridge/features/profile/presentation/pages/profile_screen.dart';
import 'package:carebridge/features/booking/presentation/pages/booking_history_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _selectedIndex = 0;

  List<Widget> _getPages(String? role) {
    return [
      role == 'caretaker' ? const CaretakerHomeScreen() : const HomeScreen(),
      const BookingHistoryScreen(), // Shows history for both roles
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return const LandingScreen();
    }

    final user = authState.user;
    debugPrint("MAIN_LAYOUT: Current Role is -> ${user.role}");

    final pages = _getPages(user.role);
    final activeColor = user.role == 'caretaker'
        ? AppTheme.safetyTeal
        : AppTheme.brandBlueGreen;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.milkyWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: activeColor,
          unselectedItemColor: Colors.black26,
          selectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded, color: activeColor),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_rounded),
              activeIcon: Icon(Icons.history_rounded, color: activeColor),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded, color: activeColor),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

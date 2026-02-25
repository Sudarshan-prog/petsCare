import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/features/home/presentation/pages/home_screen.dart';
import 'package:carebridge/features/home/presentation/pages/caretaker_home_screen.dart';
import 'package:carebridge/features/auth/presentation/pages/landing_screen.dart';
import 'package:carebridge/features/profile/presentation/pages/profile_screen.dart';
import 'package:carebridge/features/wellness/presentation/pages/wellness_assistant_screen.dart';
import 'package:carebridge/features/resources/presentation/pages/resource_center_screen.dart';

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
      _buildPlaceholderPage(
        role == 'caretaker' ? 'My Appointments' : 'Find a Furry Friend',
        role == 'caretaker'
            ? Icons.calendar_month_rounded
            : Icons.favorite_rounded,
      ),
      role == 'caretaker'
          ? const ResourceCenterScreen()
          : const WellnessAssistantScreen(),
      const ProfileScreen(),
    ];
  }

  static Widget _buildPlaceholderPage(String title, IconData icon) {
    return Scaffold(
      backgroundColor: AppTheme.softCream,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.brandBlueGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.brandBlueGreen, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coming soon in Phase 4',
                style: TextStyle(color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
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
      body: pages[_selectedIndex],
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
              icon: Icon(user.role == 'caretaker'
                  ? Icons.calendar_today_outlined
                  : Icons.pets_outlined),
              activeIcon: Icon(
                  user.role == 'caretaker'
                      ? Icons.calendar_today_rounded
                      : Icons.pets_rounded,
                  color: activeColor),
              label: user.role == 'caretaker' ? 'Bookings' : 'Friends',
            ),
            BottomNavigationBarItem(
              icon: Icon(user.role == 'caretaker'
                  ? Icons.menu_book_outlined
                  : Icons.chat_bubble_outline),
              activeIcon: Icon(
                  user.role == 'caretaker'
                      ? Icons.menu_book_rounded
                      : Icons.chat_bubble_rounded,
                  color: activeColor),
              label: user.role == 'caretaker' ? 'Resources' : 'Wellness',
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

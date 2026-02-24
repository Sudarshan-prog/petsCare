import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/features/home/presentation/pages/home_screen.dart';
import 'package:carebridge/features/home/presentation/pages/caretaker_home_screen.dart';
import 'package:carebridge/features/auth/presentation/pages/landing_screen.dart';
import 'package:carebridge/features/profile/presentation/pages/profile_screen.dart';

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
      _buildPlaceholderPage(
        role == 'caretaker' ? 'Caretaker Resources' : 'AI Wellness Assistant',
        role == 'caretaker'
            ? Icons.menu_book_rounded
            : Icons.chat_bubble_rounded,
      ),
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
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (v) => setState(() => _selectedIndex = v),
          backgroundColor: AppTheme.milkyWhite,
          selectedItemColor: activeColor,
          unselectedItemColor: Colors.black26,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(user.role == 'caretaker'
                  ? Icons.calendar_month_rounded
                  : Icons.favorite_rounded),
              label: user.role == 'caretaker' ? 'Business' : 'Adopt',
            ),
            BottomNavigationBarItem(
              icon: Icon(user.role == 'caretaker'
                  ? Icons.menu_book_rounded
                  : Icons.chat_bubble_rounded),
              label: user.role == 'caretaker' ? 'Tools' : 'AI Care',
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

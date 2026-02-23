import 'package:flutter/material.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/features/home/presentation/pages/home_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    _buildPlaceholderPage('Find a Furry Friend', Icons.favorite_rounded),
    _buildPlaceholderPage('AI Wellness Assistant', Icons.chat_bubble_rounded),
    _buildPlaceholderPage('Pet Parent Profile', Icons.person_rounded),
  ];

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
                'Coming soon in Phase 3',
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
    return Scaffold(
      body: _pages[_selectedIndex],
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
          selectedItemColor: AppTheme.brandBlueGreen,
          unselectedItemColor: Colors.black26,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite_rounded), label: 'Adopt'),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded), label: 'AI Care'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

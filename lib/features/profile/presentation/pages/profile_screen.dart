import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/features/auth/presentation/pages/landing_screen.dart';
import 'package:carebridge/features/booking/presentation/pages/booking_history_screen.dart';
import 'package:carebridge/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:carebridge/features/profile/presentation/pages/my_pets_screen.dart';
import 'package:carebridge/features/profile/presentation/pages/earnings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: AppTheme.softCream,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Profile Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.brandBlueGreen.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(
                          user?.effectiveProfileUrl ??
                              'https://api.dicebear.com/7.x/adventurer/png?seed=fallback',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'User Name',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                    ),
                    Text(
                      user?.email ?? 'user@example.com',
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Profile Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildProfileItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profile',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    if (user?.role == 'owner')
                      _buildProfileItem(
                        icon: Icons.pets_outlined,
                        title: 'My Pets',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyPetsScreen(),
                            ),
                          );
                        },
                      ),
                    if (user?.role == 'caretaker')
                      _buildProfileItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Earnings & Wallet',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EarningsScreen(),
                            ),
                          );
                        },
                      ),
                    _buildProfileItem(
                      icon: Icons.history_rounded,
                      title: 'Booking History',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BookingHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildProfileItem(
                      icon: Icons.security_rounded,
                      title: 'Privacy & Certificate',
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),

                    // Logout Button
                    _buildProfileItem(
                      icon: Icons.logout_rounded,
                      title: 'Log Out',
                      color: AppTheme.alertRed,
                      onTap: () {
                        _showLogoutDialog(context, ref);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withOpacity(0.03)),
        ),
        tileColor: Colors.white,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 16, color: color.withOpacity(0.3)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of CareBridge?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.black45)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LandingScreen()),
                (route) => false,
              );
            },
            child: const Text('Log Out',
                style: TextStyle(
                    color: AppTheme.alertRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

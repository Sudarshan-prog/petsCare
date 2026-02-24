import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CaretakerHomeScreen extends ConsumerWidget {
  const CaretakerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: AppTheme.softCream,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, user?.name ?? 'Professional'),
                const SizedBox(height: 30),
                _buildEarningsCard(context),
                const SizedBox(height: 30),
                _buildStatusToggle(context),
                const SizedBox(height: 40),
                _buildSectionLabel('Incoming Requests'),
                const SizedBox(height: 16),
                _buildRequestList(context),
                const SizedBox(height: 40),
                _buildSectionLabel('Business Toolkit'),
                const SizedBox(height: 16),
                _buildToolGrid(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Caretaker Portal',
                style: TextStyle(
                    color: AppTheme.safetyTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2),
              ),
              Text(
                'Welcome, $name!',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        CircleAvatar(
          radius: 25,
          backgroundColor: AppTheme.safetyTeal.withOpacity(0.1),
          backgroundImage: const CachedNetworkImageProvider(
              'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?auto=format&fit=crop&q=80&w=200'),
        ),
      ],
    );
  }

  Widget _buildEarningsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.safetyTeal,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: AppTheme.safetyTeal.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const Text('Total Revenue',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('₹ 12,450',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Active Pets', '03'),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildStat('Rating', '4.9 ⭐'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatusToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                    color: Colors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              const Text('Open for New Bookings',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          Switch.adaptive(
            value: true,
            onChanged: (val) {},
            activeColor: AppTheme.safetyTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildRequestList(BuildContext context) {
    return Column(
      children: [
        _buildRequestItem(
            'Buddy', 'Golden Retriever', 'Today, 2:00 PM', '₹ 500'),
        const SizedBox(height: 12),
        _buildRequestItem('Luna', 'Persian Cat', 'Tomorrow, 10:00 AM', '₹ 450'),
      ],
    );
  }

  Widget _buildRequestItem(
      String petName, String type, String time, String price) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppTheme.safetyTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(FontAwesomeIcons.paw,
                color: AppTheme.safetyTeal, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(petName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('$type • $time',
                    style:
                        const TextStyle(color: Colors.black45, fontSize: 12)),
              ],
            ),
          ),
          Text(price,
              style: const TextStyle(
                  color: AppTheme.safetyTeal, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildToolGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildToolItem('Verification',
                    FontAwesomeIcons.shieldHalved, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildToolItem('My Services',
                    FontAwesomeIcons.clipboardCheck, Colors.orange)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildToolItem(
                    'Photos', FontAwesomeIcons.images, Colors.purple)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildToolItem(
                    'Analytics', FontAwesomeIcons.chartLine, Colors.green)),
          ],
        ),
      ],
    );
  }

  Widget _buildToolItem(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softCream,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 30),

                // Search Bar inspired by the clean UI
                _buildSearchBar(context),
                const SizedBox(height: 30),

                _buildSectionTitle(context, 'Premium Services'),
                const SizedBox(height: 16),
                _buildServiceGrid(context),

                const SizedBox(height: 40),
                _buildSectionTitle(context, 'Verified Professionals'),
                const SizedBox(height: 16),
                _buildFeaturedCaretakers(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_rounded,
                    color: AppTheme.safetyTeal, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'CareBridge Secured',
                  style: TextStyle(
                    color: AppTheme.safetyTeal,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Hello, Rahul! 👋',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppTheme.brandBlueGreen.withOpacity(0.2), width: 2),
          ),
          child: const CircleAvatar(
            radius: 25,
            backgroundImage:
                NetworkImage('https://images.pravatar.cc/150?img=11'),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search_rounded, color: AppTheme.brandBlueGreen),
          hintText: 'Search for caretakers, clinics...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildServiceGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildServiceItem(context, 'Caretaking', FontAwesomeIcons.shieldHeart,
            AppTheme.brandBlueGreen),
        _buildServiceItem(
            context, 'Adopt', FontAwesomeIcons.paw, AppTheme.safetyTeal),
        _buildServiceItem(context, 'AI Wellness', FontAwesomeIcons.robot,
            Colors.deepPurpleAccent),
        _buildServiceItem(context, 'SOS Help', FontAwesomeIcons.truckMedical,
            AppTheme.alertRed),
      ],
    );
  }

  Widget _buildServiceItem(
      BuildContext context, String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCaretakers(BuildContext context) {
    return Column(
      children: [
        _buildCaretakerItem(
          name: 'Rahul Sharma',
          role: 'Pro Dog Specialist',
          dist: '1.2 km',
          price: '₹450',
          rating: '4.9',
          isPro: true,
          image:
              'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?auto=format&fit=crop&q=80&w=200',
        ),
        const SizedBox(height: 16),
        _buildCaretakerItem(
          name: 'Anjali Verma',
          role: 'Cat & Kitten Expert',
          dist: '2.4 km',
          price: '₹500',
          rating: '4.8',
          isPro: false,
          image:
              'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&q=80&w=200',
        ),
      ],
    );
  }

  Widget _buildCaretakerItem({
    required String name,
    required String role,
    required String dist,
    required String price,
    required String rating,
    required bool isPro,
    required String image,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child:
                Image.network(image, width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.verified_user_rounded,
                      color: isPro ? AppTheme.verifyGold : AppTheme.safetyTeal,
                      size: 16,
                    ),
                  ],
                ),
                Text('$role • $dist',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black45)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppTheme.verifyGold, size: 16),
                    Text(' $rating',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(
                      '$price/day',
                      style: const TextStyle(
                        color: AppTheme.brandBlueGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carebridge/models/enums.dart';

import 'package:carebridge/features/booking/presentation/providers/booking_provider.dart';
import 'package:carebridge/features/booking/data/models/booking_model.dart';
import 'package:carebridge/core/providers/caretaker_provider.dart';
import 'package:carebridge/features/booking/presentation/pages/booking_screen.dart';
import 'package:carebridge/features/home/presentation/widgets/service_grid.dart';
import 'package:carebridge/features/home/presentation/widgets/owner_booking_card.dart';
import 'package:carebridge/features/home/presentation/widgets/caretaker_list_item.dart';

final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    String userName = 'Rahul'; // Default fallback
    String profileImg = 'https://images.pravatar.cc/150?img=11';

    if (authState is AuthAuthenticated) {
      userName = authState.user.name.split(' ')[0]; // Just the first name
      profileImg = authState.user.effectiveProfileUrl;
    }

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
                _buildHeader(context, userName, profileImg),
                const SizedBox(height: 30),

                // Search Bar
                _buildSearchBar(context, ref),
                const SizedBox(height: 30),

                _buildSectionTitle(context, 'Premium Services'),
                const SizedBox(height: 16),
                const ServiceGrid(),

                const SizedBox(height: 40),
                _buildMyBookings(context, ref),

                const SizedBox(height: 40),
                _buildSectionTitle(context, 'Verified Professionals'),
                const SizedBox(height: 16),
                _buildFeaturedCaretakers(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String image) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
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
                'Hello, $name! 👋',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 24, // Explicit size to prevent unexpected scaling
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppTheme.brandBlueGreen.withOpacity(0.2), width: 2),
          ),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: AppTheme.brandBlueGreen.withOpacity(0.1),
            backgroundImage: CachedNetworkImageProvider(image),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
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
      child: TextField(
        onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
        decoration: const InputDecoration(
          icon: Icon(Icons.search_rounded, color: AppTheme.brandBlueGreen),
          hintText: 'Search for caretakers, specialties...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildMyBookings(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(ownerBookingsStreamProvider);

    return bookingsAsync.when(
      data: (bookings) {
        // ARCHITECT: Filter out completed bookings. They belong in history.
        final activeBookings = bookings
            .where((b) => b.status != BookingStatus.completed && b.status != BookingStatus.cancelled)
            .toList();

        if (activeBookings.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('You have no active bookings yet.',
                style: TextStyle(color: Colors.black26, fontSize: 12)),
          );
        }

        // Sort bookings by date (most recent first)
        final sortedBookings = List<Booking>.from(activeBookings)
          ..sort((a, b) => b.date.compareTo(a.date));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'My Bookings'),
            const SizedBox(height: 16),
            SizedBox(
              height: 360,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: sortedBookings.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return OwnerBookingCard(booking: sortedBookings[index]);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error loading bookings: $err',
            style: const TextStyle(color: AppTheme.alertRed, fontSize: 12)),
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

  Widget _buildFeaturedCaretakers(BuildContext context, WidgetRef ref) {
    final nearbyCaretakersAsync = ref.watch(nearbyCaretakersProvider);
    final query = ref.watch(searchQueryProvider).toLowerCase();

    return nearbyCaretakersAsync.when(
      data: (caretakersWithDist) {
        var filteredList = caretakersWithDist;
        if (query.isNotEmpty) {
          filteredList = caretakersWithDist.where((item) {
            final c = item['caretaker'] as Caretaker;
            final matchesName = c.name.toLowerCase().contains(query);
            final matchesSpecialty = c.specialties.any((s) => s.toLowerCase().contains(query));
            return matchesName || matchesSpecialty;
          }).toList();
        }

        if (filteredList.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('No verified professionals match your search.',
                  style: TextStyle(color: Colors.black45)),
            ),
          );
        }

        return Column(
          children: filteredList.map((item) {
            final caretaker = item['caretaker'] as Caretaker;
            final distance = item['distance'] as double?;
            final distStr = distance != null
                ? '${distance.toStringAsFixed(1)} km away'
                : 'Nearby';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CaretakerListItem(
                name: caretaker.name,
                role: caretaker.specialties.take(2).join(' & ') + ' Expert',
                dist: distStr,
                price: '₹${caretaker.price.toStringAsFixed(0)}',
                rating: caretaker.rating.toStringAsFixed(1),
                isPro: caretaker.isVerified,
                image: caretaker.profileUrl ??
                    'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?auto=format&fit=crop&q=80&w=200',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(caretaker: caretaker),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error loading caretakers: $err'),
    );
  }
}

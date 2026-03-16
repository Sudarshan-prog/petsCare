import 'package:flutter/material.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carebridge/models/enums.dart';

import 'package:carebridge/features/booking/presentation/providers/booking_provider.dart';
import 'package:carebridge/features/booking/data/models/booking_model.dart';
import 'package:carebridge/core/providers/caretaker_provider.dart';
import 'package:carebridge/features/booking/presentation/pages/booking_screen.dart';
import 'package:carebridge/features/booking/presentation/widgets/rating_dialog.dart';

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
                _buildSearchBar(context),
                const SizedBox(height: 30),

                _buildSectionTitle(context, 'Premium Services'),
                const SizedBox(height: 16),
                _buildServiceGrid(context),

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
                      fontSize:
                          24, // Explicit size to prevent unexpected scaling
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

  Widget _buildMyBookings(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(ownerBookingsStreamProvider);

    return bookingsAsync.when(
      data: (bookings) {
        // ARCHITECT: Filter out completed bookings. They belong in history.
        final activeBookings =
            bookings.where((b) => b.status != 'completed').toList();

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
                  return _buildOwnerBookingItem(
                      context, ref, sortedBookings[index]);
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

  Widget _buildOwnerBookingItem(
      BuildContext context, WidgetRef ref, Booking booking) {
    // ARCHITECTURAL DIAGNOSTIC: Log data to terminal
    debugPrint("--- OWNER_BOOKING_CARD ---");
    debugPrint("ID: ${booking.id}");
    debugPrint("STATUS: ${booking.status}");
    debugPrint("IMG_URL: ${booking.statusImageUrl}");

    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.access_time_rounded;

    if (booking.status == BookingStatus.confirmed) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
    } else if (booking.status == BookingStatus.completed) {
      statusColor = Colors.blueGrey;
      statusIcon = Icons.task_alt_rounded;
    } else if (booking.status == BookingStatus.cancelled) {
      statusColor = AppTheme.alertRed;
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                booking.status.name.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            booking.caretakerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            '${booking.services.isEmpty ? 'General Care' : booking.services.join(', ')} • ${booking.petName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            '₹${booking.totalPrice} • ${booking.hours}h',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.brandBlueGreen,
                fontSize: 12),
          ),
          if (booking.statusImageUrl != null &&
              booking.statusImageUrl!.startsWith('http')) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            color: Colors.black87,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: InteractiveViewer(
                            child: CachedNetworkImage(
                              imageUrl: booking.statusImageUrl!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          right: 20,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 30),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: booking.statusImageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 120,
                        width: double.infinity,
                        color: AppTheme.brandBlueGreen.withOpacity(0.05),
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.fullscreen_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Tap to Expand',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.safetyTeal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIVE PHOTO',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (booking.status == BookingStatus.pending) ...[
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final now = DateTime.now();
                final creationTime = booking.createdAt ?? now;
                final diff = now.difference(creationTime);
                final bool canCancel = diff.inHours >= 2;

                if (!canCancel) {
                  return Text(
                    'Caretaker has ${2 - diff.inHours}h remaining to respond.',
                    style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.black26,
                        fontSize: 10),
                  );
                }

                return Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cancel Request?'),
                          content: const Text(
                              'The caretaker hasn\'t responded in 2 hours. Would you like to cancel and release your funds instantly?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Keep Waiting')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Yes, Cancel Now',
                                    style:
                                        TextStyle(color: AppTheme.alertRed))),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await ref
                            .read(bookingProvider.notifier)
                            .updateBookingStatus(booking.id!, 'cancelled');
                        ref.invalidate(ownerBookingsStreamProvider);
                      }
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 14),
                    label: const Text('Cancel Request',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.alertRed,
                      side: const BorderSide(color: AppTheme.alertRed),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                );
              },
            ),
          ],
          if (booking.status == BookingStatus.confirmed) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Pet Handover?'),
                      content: const Text(
                          'Have you received your pet safely? This will end the session and purge all status photos to save storage cost.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Not Yet')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Yes, Finished',
                                style: TextStyle(color: AppTheme.safetyTeal))),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref
                        .read(bookingProvider.notifier)
                        .updateBookingStatus(booking.id!, 'completed');

                    if (context.mounted) {
                      final double? rating = await showDialog<double>(
                        context: context,
                        builder: (context) => CaretakerRatingDialog(
                          caretakerName: booking.caretakerName,
                        ),
                      );

                      if (rating != null) {
                        await ref
                            .read(bookingProvider.notifier)
                            .rateCaretaker(booking.caretakerId, rating);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  '✨ Rating submitted! Thank you for your feedback.'),
                              backgroundColor: AppTheme.safetyTeal,
                            ),
                          );
                        }
                      }
                    }

                    ref.invalidate(ownerBookingsStreamProvider);
                  }
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                label: const Text('Finish Job',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.safetyTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildServiceItem(context, 'Caretaking',
                  FontAwesomeIcons.shieldHeart, AppTheme.brandBlueGreen),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildServiceItem(
                  context, 'Adopt', FontAwesomeIcons.paw, AppTheme.safetyTeal),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildServiceItem(context, 'AI Wellness',
                  FontAwesomeIcons.robot, Colors.deepPurpleAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildServiceItem(context, 'SOS Help',
                  FontAwesomeIcons.truckMedical, AppTheme.alertRed),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceItem(
      BuildContext context, String title, IconData icon, Color color) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: Container(
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
      ),
    );
  }

  Widget _buildFeaturedCaretakers(BuildContext context, WidgetRef ref) {
    final nearbyCaretakersAsync = ref.watch(nearbyCaretakersProvider);

    return nearbyCaretakersAsync.when(
      data: (caretakersWithDist) {
        if (caretakersWithDist.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('No verified professionals nearby yet.',
                  style: TextStyle(color: Colors.black45)),
            ),
          );
        }

        return Column(
          children: caretakersWithDist.map((item) {
            final caretaker = item['caretaker'] as Caretaker;
            final distance = item['distance'] as double?;
            final distStr = distance != null
                ? '${distance.toStringAsFixed(1)} km away'
                : 'Nearby';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCaretakerItem(
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

  Widget _buildCaretakerItem({
    required String name,
    required String role,
    required String dist,
    required String price,
    required String rating,
    required bool isPro,
    required String image,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
              child: CachedNetworkImage(
                imageUrl: image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.safetyTeal.withOpacity(0.1),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.safetyTeal.withOpacity(0.1),
                  child: const Icon(Icons.error_outline,
                      color: AppTheme.safetyTeal),
                ),
              ),
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
                        color:
                            isPro ? AppTheme.verifyGold : AppTheme.safetyTeal,
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
                        '$price/hour',
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
      ),
    );
  }
}

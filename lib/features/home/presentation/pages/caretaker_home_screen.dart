import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carebridge/core/providers/caretaker_provider.dart';
import 'package:carebridge/features/booking/presentation/providers/booking_provider.dart';
import 'package:carebridge/features/booking/data/models/booking_model.dart';
import 'package:intl/intl.dart';

class CaretakerHomeScreen extends ConsumerWidget {
  const CaretakerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final caretakerAsync = ref.watch(singleCaretakerProvider(user.id));
    final bookingsAsync = ref.watch(caretakerBookingsStreamProvider);

    return caretakerAsync.when(
      data: (caretaker) => Scaffold(
        backgroundColor: AppTheme.softCream,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, user.name,
                      caretaker?.profileUrl ?? user.profileUrl),
                  const SizedBox(height: 30),
                  _buildEarningsCard(
                      context, caretaker, bookingsAsync.value ?? []),
                  const SizedBox(height: 30),
                  _buildStatusToggle(context),
                  const SizedBox(height: 40),
                  _buildSectionLabel('Incoming Requests'),
                  const SizedBox(height: 16),
                  _buildRequestList(context, ref, bookingsAsync),
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
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String? profileUrl) {
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
          backgroundImage: CachedNetworkImageProvider(profileUrl ??
              'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?auto=format&fit=crop&q=80&w=200'),
        ),
      ],
    );
  }

  Widget _buildEarningsCard(
      BuildContext context, Caretaker? caretaker, List<Booking> bookings) {
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
              _buildStat('Total Bookings', bookings.length.toString()),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildStat('Rating', '${caretaker?.rating ?? '5.0'} ⭐'),
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

  Widget _buildRequestList(BuildContext context, WidgetRef ref,
      AsyncValue<List<Booking>> bookingsAsync) {
    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
            ),
            child: Column(
              children: [
                Icon(FontAwesomeIcons.calendarCheck,
                    color: AppTheme.safetyTeal.withOpacity(0.2), size: 40),
                const SizedBox(height: 16),
                const Text(
                  'No active requests yet',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Text(
                  'New pet bookings will appear here.',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          );
        }
        return Column(
          children: bookings
              .map((booking) => _buildBookingItem(ref, booking))
              .toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Text('Error: $e'),
    );
  }

  Widget _buildBookingItem(WidgetRef ref, Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
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
                    Row(
                      children: [
                        Text(booking.petName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.brandBlueGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${booking.hours}h',
                            style: const TextStyle(
                                color: AppTheme.brandBlueGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Text(
                        '${booking.serviceType} • ${DateFormat('MMM d').format(booking.date)} at ${booking.timeSlot}',
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${booking.totalPrice}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandBlueGreen),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(
                          color: _getStatusColor(booking.status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (booking.status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(bookingProvider.notifier)
                        .updateBookingStatus(booking.id!, 'cancelled'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.alertRed,
                      side: const BorderSide(color: AppTheme.alertRed),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref
                        .read(bookingProvider.notifier)
                        .updateBookingStatus(booking.id!, 'confirmed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.safetyTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return AppTheme.alertRed;
      default:
        return Colors.grey;
    }
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

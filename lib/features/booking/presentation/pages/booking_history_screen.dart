import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/features/booking/presentation/providers/booking_provider.dart';
import 'package:carebridge/features/booking/data/models/booking_model.dart';
import 'package:intl/intl.dart';

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(ownerBookingsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.softCream,
      appBar: AppBar(
        title: const Text('Booking History',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          final historyBookings = bookings
              .where((b) => b.status == 'completed' || b.status == 'cancelled')
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          if (historyBookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: Colors.black12),
                  const SizedBox(height: 16),
                  const Text('No booking history yet',
                      style: TextStyle(
                          color: Colors.black45, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            itemCount: historyBookings.length,
            itemBuilder: (context, index) {
              final booking = historyBookings[index];
              return _buildHistoryItem(context, booking);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Booking booking) {
    final bool isCompleted = booking.status == 'completed';
    final Color statusColor = isCompleted ? Colors.blueGrey : AppTheme.alertRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCompleted
                          ? Icons.task_alt_rounded
                          : Icons.cancel_rounded,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d, yyyy').format(booking.date),
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            booking.caretakerName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            '${booking.services.join(", ")} • ${booking.petName}',
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Paid: ₹${booking.totalPrice}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandBlueGreen,
                  fontSize: 15,
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.black12),
            ],
          ),
        ],
      ),
    );
  }
}

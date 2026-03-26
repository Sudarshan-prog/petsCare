import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/models/enums.dart';
import 'package:carebridge/features/booking/data/models/booking_model.dart';
import 'package:carebridge/features/booking/presentation/providers/booking_provider.dart';
import 'package:carebridge/features/booking/presentation/widgets/rating_dialog.dart';

class OwnerBookingCard extends ConsumerWidget {
  final Booking booking;

  const OwnerBookingCard({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

                      if (confirmed == true && booking.id != null) {
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
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

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

                  if (confirmed == true && booking.id != null) {
                    // Cache the notifier reference IMMEDIATELY before starting any async operations.
                    // Once we update the status, the Firestore stream will instantly rebuild
                    // this card into "completed" state, ripping this very button out of the Widget Tree.
                    // Doing ref.read() after that await would crash instantly!
                    final bookingNotifier = ref.read(bookingProvider.notifier);
                    
                    await bookingNotifier.updateBookingStatus(booking.id!, BookingStatus.completed.name);

                    if (navigator.mounted) {
                      final double? rating = await showDialog<double>(
                        context: navigator.context,
                        builder: (context) => CaretakerRatingDialog(
                          caretakerName: booking.caretakerName,
                        ),
                      );

                      if (rating != null && booking.id != null) {
                        final success = await bookingNotifier.submitRatingViaServer(
                                booking.id!, booking.caretakerId, rating);

                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? '✨ Rating submitted! Thank you for your feedback.'
                                : '❌ Rating failed. Please try again.'),
                            backgroundColor:
                                success ? AppTheme.safetyTeal : Colors.red,
                          ),
                        );
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
}

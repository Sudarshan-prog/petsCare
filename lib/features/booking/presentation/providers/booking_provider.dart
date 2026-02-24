import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/features/booking/data/models/booking_model.dart';
import 'package:carebridge/core/auth/auth_provider.dart';

class BookingNotifier extends StateNotifier<AsyncValue<void>> {
  BookingNotifier() : super(const AsyncValue.data(null));

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createBooking(Booking booking) async {
    state = const AsyncValue.loading();
    try {
      await _firestore.collection('bookings').add(booking.toMap());
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
      });
    } catch (e) {
      debugPrint("Error updating booking status: $e");
    }
  }

  Stream<List<Booking>> getCaretakerBookings(String caretakerId) {
    return _firestore
        .collection('bookings')
        .where('caretakerId', isEqualTo: caretakerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  Stream<List<Booking>> getOwnerBookings(String ownerId) {
    return _firestore
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }
}

final bookingProvider =
    StateNotifierProvider<BookingNotifier, AsyncValue<void>>((ref) {
  return BookingNotifier();
});

final ownerBookingsStreamProvider = StreamProvider<List<Booking>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return ref
        .read(bookingProvider.notifier)
        .getOwnerBookings(authState.user.id);
  }
  return Stream.value([]);
});

final caretakerBookingsStreamProvider = StreamProvider<List<Booking>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return ref
        .read(bookingProvider.notifier)
        .getCaretakerBookings(authState.user.id);
  }
  return Stream.value([]);
});

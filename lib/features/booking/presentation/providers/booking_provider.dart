import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/features/booking/data/models/booking_model.dart';
import 'package:carebridge/core/auth/auth_provider.dart';

import 'package:carebridge/features/booking/domain/repositories/booking_repository.dart';

class BookingNotifier extends StateNotifier<AsyncValue<void>> {
  final IBookingRepository _repository;

  BookingNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createBooking(Booking booking) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createBooking(booking);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _repository.updateBookingStatus(bookingId, status);
    } catch (e) {
      debugPrint("Error updating booking status: $e");
    }
  }
}

final bookingRepositoryProvider = Provider<IBookingRepository>((ref) {
  return BookingRepository();
});

final bookingProvider =
    StateNotifierProvider<BookingNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(bookingRepositoryProvider);
  return BookingNotifier(repo);
});

final ownerBookingsStreamProvider = StreamProvider<List<Booking>>((ref) {
  final authState = ref.watch(authProvider);
  final repo = ref.watch(bookingRepositoryProvider);
  if (authState is AuthAuthenticated) {
    return repo.getOwnerBookings(authState.user.id);
  }
  return Stream.value([]);
});

final caretakerBookingsStreamProvider = StreamProvider<List<Booking>>((ref) {
  final authState = ref.watch(authProvider);
  final repo = ref.watch(bookingRepositoryProvider);
  if (authState is AuthAuthenticated) {
    return repo.getCaretakerBookings(authState.user.id);
  }
  return Stream.value([]);
});

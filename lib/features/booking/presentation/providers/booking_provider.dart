import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/features/booking/data/models/booking_model.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/core/repositories/storage_repository.dart';
import 'package:carebridge/features/booking/domain/repositories/booking_repository.dart';

class BookingNotifier extends StateNotifier<AsyncValue<void>> {
  final IBookingRepository _repository;
  final IStorageRepository _storage;

  BookingNotifier(this._repository, this._storage)
      : super(const AsyncValue.data(null));

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
      // ARCHITECT: If completing or cancelling, we should physically delete the photo from cloud storage
      if (status == 'completed' || status == 'cancelled') {
        debugPrint("🧹 ARCHITECT: Purging final photo for finished booking...");
        final booking = await _repository.getBookingById(bookingId);
        if (booking?.statusImageUrl != null &&
            booking!.statusImageUrl!.startsWith('http')) {
          await _storage.deleteImage(booking.statusImageUrl!);
          debugPrint("🗑️ ARCHITECT: Cloud storage cleared!");
        }
      }

      await _repository.updateBookingStatus(bookingId, status);

      // If we are marking it as completed/cancelled, also clear the image URL from DB
      if (status == 'completed' || status == 'cancelled') {
        await _repository.updateBookingImageUrl(bookingId, null);
      }
    } catch (e) {
      debugPrint("Error updating booking status: $e");
    }
  }

  Future<void> sendPhotoUpdate(String bookingId, File photo) async {
    state = const AsyncValue.loading();
    try {
      debugPrint("🚀 ARCHITECT: Starting Single-Photo Update for: $bookingId");

      // 1. ARCHITECT CLEANUP: Find and delete the previous photo first
      final existingBooking = await _repository.getBookingById(bookingId);
      if (existingBooking?.statusImageUrl != null &&
          existingBooking!.statusImageUrl!.startsWith('http')) {
        debugPrint("♻️ ARCHITECT: Deleting previous photo to save space...");
        await _storage.deleteImage(existingBooking.statusImageUrl!);
      }

      // 2. Upload the new photo
      final imageUrl = await _storage.uploadBookingUpdate(bookingId, photo);
      debugPrint("🔗 ARCHITECT: New Photo URL: $imageUrl");

      // 3. Update DB
      await _repository.updateBookingImageUrl(bookingId, imageUrl);
      debugPrint("✅ ARCHITECT: Update Complete!");
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint("❌ ARCHITECT ERROR: sendPhotoUpdate failed: $e");
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final bookingRepositoryProvider = Provider<IBookingRepository>((ref) {
  return BookingRepository();
});

final bookingProvider =
    StateNotifierProvider<BookingNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(bookingRepositoryProvider);
  final storage = ref.watch(storageRepositoryProvider);
  return BookingNotifier(repo, storage);
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

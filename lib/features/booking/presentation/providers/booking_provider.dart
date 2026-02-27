import 'dart:io';
import 'package:carebridge/core/providers/payment_provider.dart';
import 'package:carebridge/core/repositories/payment_repository_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/features/booking/data/models/booking_model.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/core/repositories/storage_repository.dart';
import 'package:carebridge/features/booking/domain/repositories/booking_repository.dart';
import 'package:carebridge/core/repositories/caretaker_repository.dart';
import 'package:carebridge/core/providers/caretaker_provider.dart';

class BookingNotifier extends StateNotifier<AsyncValue<void>> {
  final IBookingRepository _repository;
  final IStorageRepository _storage;
  final ICaretakerRepository _caretakerRepository;
  final IPaymentRepository _paymentRepository;

  BookingNotifier(this._repository, this._storage, this._caretakerRepository,
      this._paymentRepository)
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
      final booking = await _repository.getBookingById(bookingId);
      if (booking == null) return;

      // ARCHITECT: BLUEPRINT A - AUTHORIZE & CAPTURE LOGIC
      if (status == 'confirmed' && booking.paymentStatus == 'authorized') {
        debugPrint("💰 ARCHITECT: Caretaker ACCEPTED. Capturing funds...");
        if (booking.paymentId != null) {
          await _paymentRepository.capturePayment(
              booking.paymentId!, booking.totalPrice);
          await _repository.updateBookingPaymentStatus(bookingId, 'paid');
        }
      } else if (status == 'cancelled' &&
          booking.paymentStatus == 'authorized') {
        debugPrint(
            "🛡️ ARCHITECT: Caretaker REJECTED. Releasing authorization (FREE)...");
        if (booking.paymentId != null) {
          await _paymentRepository.releasePayment(booking.paymentId!);
          await _repository.updateBookingPaymentStatus(bookingId, 'released');
        }
      } else if (status == 'cancelled' && booking.paymentStatus == 'paid') {
        // This is a post-acceptance cancellation (requires standard refund)
        debugPrint(
            "⚠️ ARCHITECT: Post-acceptance cancellation. Refunding (Standard Fee applies)...");
        if (booking.paymentId != null) {
          await _paymentRepository.refundPayment(booking.paymentId!);
          await _repository.updateBookingPaymentStatus(bookingId, 'refunded');
        }
      }

      // ARCHITECT: Purge photos if job is finished
      if (status == 'completed' || status == 'cancelled') {
        if (booking.statusImageUrl != null &&
            booking.statusImageUrl!.startsWith('http')) {
          await _storage.deleteImage(booking.statusImageUrl!);
        }
      }

      await _repository.updateBookingStatus(bookingId, status);

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
      final existingBooking = await _repository.getBookingById(bookingId);
      if (existingBooking?.statusImageUrl != null &&
          existingBooking!.statusImageUrl!.startsWith('http')) {
        await _storage.deleteImage(existingBooking.statusImageUrl!);
      }

      final imageUrl = await _storage.uploadBookingUpdate(bookingId, photo);
      await _repository.updateBookingImageUrl(bookingId, imageUrl);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> rateCaretaker(String caretakerId, double rating) async {
    try {
      await _caretakerRepository.updateCaretakerRating(caretakerId, rating);
    } catch (e) {
      debugPrint("Error rating caretaker: $e");
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
  final caretakerRepo = ref.watch(caretakerRepositoryProvider);
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  return BookingNotifier(repo, storage, caretakerRepo, paymentRepo);
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

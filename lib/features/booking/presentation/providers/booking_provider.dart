import 'dart:io';
import 'package:carebridge/core/providers/payment_provider.dart';
import 'package:carebridge/core/repositories/payment_repository_interface.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  final FirebaseFunctions _functions;

  BookingNotifier(this._repository, this._storage, this._caretakerRepository,
      this._paymentRepository)
      : _functions = FirebaseFunctions.instance,
        super(const AsyncValue.data(null));

  /// PHASE 2: Create booking via Cloud Function (server-side price calculation)
  Future<Map<String, dynamic>?> createBookingViaServer({
    required String caretakerId,
    required String petId,
    required String petName,
    required List<String> services,
    required int hours,
    required String date,
    required String timeSlot,
    String? notes,
    String? paymentId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result =
          await _functions.httpsCallable('createBooking').call({
        'caretakerId': caretakerId,
        'petId': petId,
        'petName': petName,
        'services': services,
        'hours': hours,
        'date': date,
        'timeSlot': timeSlot,
        'notes': notes ?? '',
        'paymentId': paymentId,
      });

      final data = Map<String, dynamic>.from(result.data);
      debugPrint('✅ Booking created via Cloud Function: ${data['bookingId']}');
      debugPrint('   Total: ₹${data['totalPrice']}, Caretaker gets: ₹${data['caretakerPayout']}');

      state = const AsyncValue.data(null);
      return data;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Cloud Function error: ${e.code} - ${e.message}');
      state = AsyncValue.error(e.message ?? 'Booking failed', StackTrace.current);
      return null;
    } catch (e, stack) {
      debugPrint('❌ Booking error: $e');
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// PHASE 2: Update booking status via Cloud Function (server-side validation)
  Future<bool> updateBookingStatusViaServer(String bookingId, String newStatus) async {
    try {
      final result =
          await _functions.httpsCallable('updateBookingStatus').call({
        'bookingId': bookingId,
        'newStatus': newStatus,
      });

      final data = Map<String, dynamic>.from(result.data);
      debugPrint('✅ Status updated via Cloud Function: $bookingId → $newStatus');
      return data['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Status update error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Status update error: $e');
      return false;
    }
  }

  /// PHASE 2: Submit rating via Cloud Function (server-side validation)
  Future<bool> submitRatingViaServer(String bookingId, double rating) async {
    try {
      final result =
          await _functions.httpsCallable('submitRating').call({
        'bookingId': bookingId,
        'rating': rating,
      });

      final data = Map<String, dynamic>.from(result.data);
      debugPrint('✅ Rating submitted via Cloud Function: $rating stars');
      return data['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Rating error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Rating error: $e');
      return false;
    }
  }

  /// PHASE 2: Delete account via Cloud Function (cascade deletion)
  Future<bool> deleteAccountViaServer() async {
    try {
      final result =
          await _functions.httpsCallable('deleteAccount').call();

      final data = Map<String, dynamic>.from(result.data);
      debugPrint('✅ Account deleted via Cloud Function');
      return data['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Account deletion error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Account deletion error: $e');
      return false;
    }
  }

  // === LEGACY METHODS (kept for backward compatibility during migration) ===

  Future<void> createBooking(Booking booking) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createBooking(booking);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    // PHASE 2: Route through Cloud Function
    final success = await updateBookingStatusViaServer(bookingId, newStatus);
    if (!success) {
      debugPrint('⚠️ Cloud Function failed, falling back to direct write');
      // Fallback to direct write (will be removed in Phase 3)
      try {
        await _repository.updateBookingStatus(bookingId, newStatus);
      } catch (e) {
        debugPrint("Error updating booking status: $e");
      }
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
      if (rating < 1.0 || rating > 5.0) {
        debugPrint("⚠️ Invalid rating: $rating. Must be 1.0-5.0");
        return;
      }
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

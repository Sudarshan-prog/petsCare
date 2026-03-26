import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:carebridge/core/exceptions/app_exception.dart';
import 'package:carebridge/features/booking/data/models/booking_model.dart';

abstract class IBookingRepository {
  Stream<List<Booking>> getOwnerBookings(String ownerId);
  Stream<List<Booking>> getCaretakerBookings(String caretakerId);
  Future<void> createBooking(Booking booking);
  Future<void> updateBookingStatus(String bookingId, String status);
  Future<void> updateBookingImageUrl(String bookingId, String? imageUrl);
  Future<Booking?> getBookingById(String bookingId);
  Future<void> updateBookingPaymentStatus(String bookingId, String status);
}

class BookingRepository implements IBookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Booking>> getOwnerBookings(String ownerId) {
    return _firestore
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList())
        .handleError((error) {
      debugPrint('❌ Error fetching owner bookings: $error');
    });
  }

  @override
  Stream<List<Booking>> getCaretakerBookings(String caretakerId) {
    return _firestore
        .collection('bookings')
        .where('caretakerId', isEqualTo: caretakerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList())
        .handleError((error) {
      debugPrint('❌ Error fetching caretaker bookings: $error');
    });
  }

  @override
  Future<void> createBooking(Booking booking) async {
    try {
      await _firestore.collection('bookings').add(booking.toMap());
    } on FirebaseException catch (e) {
      throw AppException('Failed to create booking: ${e.message}',
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Unexpected error creating booking: $e',
          originalError: e);
    }
  }

  @override
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({'status': status});
    } on FirebaseException catch (e) {
      throw AppException('Failed to update booking status: ${e.message}',
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Unexpected error updating status: $e',
          originalError: e);
    }
  }

  @override
  Future<void> updateBookingImageUrl(String bookingId, String? imageUrl) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({'statusImageUrl': imageUrl});
    } on FirebaseException catch (e) {
      throw AppException('Failed to update booking image: ${e.message}',
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Unexpected error updating image: $e',
          originalError: e);
    }
  }

  @override
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc =
          await _firestore.collection('bookings').doc(bookingId).get();
      if (!doc.exists) return null;
      return Booking.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw AppException('Failed to fetch booking: ${e.message}',
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Unexpected error fetching booking: $e',
          originalError: e);
    }
  }

  @override
  Future<void> updateBookingPaymentStatus(
      String bookingId, String status) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({'paymentStatus': status});
    } on FirebaseException catch (e) {
      throw AppException('Failed to update payment status: ${e.message}',
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Unexpected error updating payment status: $e',
          originalError: e);
    }
  }
}

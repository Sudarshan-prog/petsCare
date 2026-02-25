import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carebridge/features/booking/data/models/booking_model.dart';

abstract class IBookingRepository {
  Stream<List<Booking>> getOwnerBookings(String ownerId);
  Stream<List<Booking>> getCaretakerBookings(String caretakerId);
  Future<void> createBooking(Booking booking);
  Future<void> updateBookingStatus(String bookingId, String status);
  Future<void> updateBookingImageUrl(String bookingId, String? imageUrl);
  Future<Booking?> getBookingById(String bookingId);
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
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  @override
  Stream<List<Booking>> getCaretakerBookings(String caretakerId) {
    return _firestore
        .collection('bookings')
        .where('caretakerId', isEqualTo: caretakerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  @override
  Future<void> createBooking(Booking booking) {
    return _firestore.collection('bookings').add(booking.toMap());
  }

  @override
  Future<void> updateBookingStatus(String bookingId, String status) {
    return _firestore
        .collection('bookings')
        .doc(bookingId)
        .update({'status': status});
  }

  @override
  Future<void> updateBookingImageUrl(String bookingId, String? imageUrl) {
    return _firestore
        .collection('bookings')
        .doc(bookingId)
        .update({'statusImageUrl': imageUrl});
  }

  @override
  Future<Booking?> getBookingById(String bookingId) async {
    final doc = await _firestore.collection('bookings').doc(bookingId).get();
    if (!doc.exists) return null;
    return Booking.fromFirestore(doc);
  }
}

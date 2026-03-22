import 'package:flutter_test/flutter_test.dart';
import 'package:carebridge/features/booking/data/models/booking_model.dart';
import 'package:carebridge/models/enums.dart';

void main() {
  group('Booking Model & Enum Tests', () {
    test('Booking properly calculates fees using hybrid model fallbacks', () {
      final booking = Booking(
        caretakerId: 'c1',
        caretakerName: 'John',
        ownerId: 'o1',
        ownerName: 'Alice',
        petId: 'p1',
        petName: 'Rex',
        date: DateTime.now(),
        timeSlot: '10:00 AM',
        services: ['Walking'],
        hours: 2,
        basePrice: 500.0,
      );

      // Verify that the default 5% fee model is applied correctly
      // ownerFee = 500 * 0.025 = 12.5
      expect(booking.ownerFee, 12.5);
      
      // caretakerCommission = 500 * 0.025 = 12.5
      expect(booking.caretakerCommission, 12.5);
      
      // totalPrice = 500 + 12.5 = 512.5
      expect(booking.totalPrice, 512.5);
      
      // caretakerPayout = 500 - 12.5 = 487.5
      expect(booking.caretakerPayout, 487.5);
      
      // Status defaults
      expect(booking.status, BookingStatus.pending);
      expect(booking.paymentStatus, PaymentStatus.unpaid);
    });

    test('Booking toMap outputs correct enum strings for Firestore', () {
      final booking = Booking(
        caretakerId: 'c1',
        caretakerName: 'John',
        ownerId: 'o1',
        ownerName: 'Alice',
        petId: 'p1',
        petName: 'Rex',
        date: DateTime.now(),
        timeSlot: '10:00 AM',
        services: ['Walking'],
        hours: 2,
        basePrice: 500.0,
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.authorized,
      );

      final map = booking.toMap();
      
      // Verify enum serialization to string
      expect(map['status'], 'confirmed');
      expect(map['paymentStatus'], 'authorized');
    });
  });

  group('BookingStatus Enum Transition Tests', () {
    test('Valid status transitions act correctly', () {
      expect(BookingStatus.pending.canTransitionTo(BookingStatus.confirmed), isTrue);
      expect(BookingStatus.pending.canTransitionTo(BookingStatus.cancelled), isTrue);
      expect(BookingStatus.pending.canTransitionTo(BookingStatus.completed), isFalse);

      expect(BookingStatus.confirmed.canTransitionTo(BookingStatus.completed), isTrue);
      expect(BookingStatus.confirmed.canTransitionTo(BookingStatus.cancelled), isTrue);
      expect(BookingStatus.confirmed.canTransitionTo(BookingStatus.pending), isFalse);

      expect(BookingStatus.completed.canTransitionTo(BookingStatus.cancelled), isFalse);
      expect(BookingStatus.cancelled.canTransitionTo(BookingStatus.pending), isFalse);
    });
  });
}

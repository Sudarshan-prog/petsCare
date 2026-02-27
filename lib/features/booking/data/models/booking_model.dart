import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String? id;
  final String caretakerId;
  final String caretakerName;
  final String ownerId;
  final String ownerName;
  final String petId;
  final String petName;
  final DateTime date;
  final String timeSlot;
  final List<String> services;
  final int hours;
  final double totalPrice;
  final double platformFee; // ARCHITECT: Platform's commission
  final double caretakerPayout; // ARCHITECT: Net amount for caretaker
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String? notes;
  final String? statusImageUrl;
  final String paymentStatus; // 'unpaid', 'paid', 'failed'
  final String? paymentId; // Razorpay payment ID
  final DateTime? createdAt; // ARCHITECT: Time of booking creation

  Booking({
    this.id,
    required this.caretakerId,
    required this.caretakerName,
    required this.ownerId,
    required this.ownerName,
    required this.petId,
    required this.petName,
    required this.date,
    required this.timeSlot,
    required this.services,
    required this.hours,
    required this.totalPrice,
    this.platformFee = 15.0, // Default platform fee
    this.caretakerPayout = 0.0,
    this.status = 'pending',
    this.notes,
    this.statusImageUrl,
    this.paymentStatus = 'unpaid',
    this.paymentId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'caretakerId': caretakerId,
      'caretakerName': caretakerName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'petId': petId,
      'petName': petName,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      'services': services,
      'hours': hours,
      'totalPrice': totalPrice,
      'platformFee': platformFee,
      'caretakerPayout':
          caretakerPayout == 0.0 ? (totalPrice - platformFee) : caretakerPayout,
      'status': status,
      'notes': notes,
      'statusImageUrl': statusImageUrl,
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime? parseCreatedAt(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }
// ... factory continues

    double parseDouble(dynamic value, double fallback) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    int parseInt(dynamic value, int fallback) {
      if (value == null) return fallback;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    return Booking(
      id: doc.id,
      caretakerId: data['caretakerId'] ?? '',
      caretakerName: data['caretakerName'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      petId: data['petId'] ?? '',
      petName: data['petName'] ?? '',
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      timeSlot: data['timeSlot'] ?? '',
      services: List<String>.from(data['services'] ?? []),
      hours: parseInt(data['hours'], 1),
      totalPrice: parseDouble(data['totalPrice'], 0.0),
      platformFee: parseDouble(data['platformFee'], 15.0),
      caretakerPayout: parseDouble(data['caretakerPayout'], 0.0),
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      statusImageUrl: data['statusImageUrl'],
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      paymentId: data['paymentId'],
      createdAt: parseCreatedAt(data['createdAt']),
    );
  }
}

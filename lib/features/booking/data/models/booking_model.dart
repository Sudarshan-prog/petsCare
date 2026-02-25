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
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String? notes;
  final String? statusImageUrl;

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
    this.status = 'pending',
    this.notes,
    this.statusImageUrl,
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
      'status': status,
      'notes': notes,
      'statusImageUrl': statusImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

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
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      statusImageUrl: data['statusImageUrl'],
    );
  }
}

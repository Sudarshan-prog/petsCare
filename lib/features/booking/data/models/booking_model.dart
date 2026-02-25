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
  final String serviceType;
  final int hours;
  final double totalPrice;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String? notes;

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
    required this.serviceType,
    required this.hours,
    required this.totalPrice,
    this.status = 'pending',
    this.notes,
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
      'serviceType': serviceType,
      'hours': hours,
      'totalPrice': totalPrice,
      'status': status,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
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
      serviceType: data['serviceType'] ?? '',
      hours: data['hours'] ?? 1,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pending',
      notes: data['notes'],
    );
  }
}

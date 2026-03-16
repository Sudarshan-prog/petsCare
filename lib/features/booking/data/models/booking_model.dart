import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carebridge/core/config/app_config.dart';
import 'package:carebridge/models/enums.dart';

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
  final double basePrice; // Service cost before fees
  final double ownerFee; // 2.5% charged to owner
  final double caretakerCommission; // 2.5% deducted from caretaker
  final double totalPrice; // What owner pays = basePrice + ownerFee
  final double caretakerPayout; // What caretaker gets = basePrice - commission
  final BookingStatus status;
  final String? notes;
  final String? statusImageUrl;
  final PaymentStatus paymentStatus;
  final String? paymentId; // Razorpay payment ID
  final DateTime? createdAt;
  final bool isRated; // Prevents duplicate ratings

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
    required this.basePrice,
    double? ownerFee,
    double? caretakerCommission,
    double? totalPrice,
    double? caretakerPayout,
    this.status = BookingStatus.pending,
    this.notes,
    this.statusImageUrl,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentId,
    this.createdAt,
    this.isRated = false,
  })  : ownerFee = ownerFee ?? AppConfig.calculateOwnerFee(basePrice),
        caretakerCommission = caretakerCommission ??
            AppConfig.calculateCaretakerCommission(basePrice),
        totalPrice = totalPrice ?? AppConfig.calculateOwnerTotal(basePrice),
        caretakerPayout =
            caretakerPayout ?? AppConfig.calculateCaretakerPayout(basePrice);

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
      'basePrice': basePrice,
      'ownerFee': ownerFee,
      'caretakerCommission': caretakerCommission,
      'totalPrice': totalPrice,
      'caretakerPayout': caretakerPayout,
      'status': status.name,
      'notes': notes,
      'statusImageUrl': statusImageUrl,
      'paymentStatus': paymentStatus.name,
      'paymentId': paymentId,
      'isRated': isRated,
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

    double? parseDouble(dynamic value, double? fallback) {
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

    final double rawBasePrice = parseDouble(data['basePrice'], 0.0) ?? 0.0;
    // Backward compatibility: if old booking used 'totalPrice' as the base
    final double rawTotal = parseDouble(data['totalPrice'], rawBasePrice) ?? 0.0;

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
      basePrice: rawBasePrice > 0 ? rawBasePrice : rawTotal,
      ownerFee: parseDouble(data['ownerFee'], null),
      caretakerCommission: parseDouble(data['caretakerCommission'], null),
      totalPrice: parseDouble(data['totalPrice'], null),
      caretakerPayout: parseDouble(data['caretakerPayout'], null),
      status: BookingStatus.fromString(data['status'] ?? 'pending'),
      notes: data['notes'],
      statusImageUrl: data['statusImageUrl'],
      paymentStatus:
          PaymentStatus.fromString(data['paymentStatus'] ?? 'unpaid'),
      paymentId: data['paymentId'],
      isRated: data['isRated'] ?? false,
      createdAt: parseCreatedAt(data['createdAt']),
    );
  }

  /// Helper for backward compatibility with code that checks status as string
  String get statusString => status.name;
  String get paymentStatusString => paymentStatus.name;
}

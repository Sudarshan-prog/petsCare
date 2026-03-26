import 'package:cloud_firestore/cloud_firestore.dart';

class Caretaker {
  final String id;
  final String name;
  final String? email;
  final String? bio;
  final List<String> specialties;
  final double price; // Base hourly rate
  final Map<String, double> serviceFees; // Dynamic premiums for specific tasks
  final double rating;
  final bool isVerified;
  final String? profileUrl;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final bool isAvailable;

  Caretaker({
    required this.id,
    required this.name,
    this.email,
    this.bio,
    this.specialties = const [],
    required this.price,
    this.serviceFees = const {
      'Walking': 50.0,
      'Bathing': 200.0,
      'Poop Cleanup': 150.0,
      'Feeding': 30.0,
    },
    this.rating = 5.0,
    this.isVerified = false,
    this.profileUrl,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    this.isAvailable = true,
  });

  factory Caretaker.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Defensive parsing for num/double fields
    double parseDouble(dynamic value, double fallback) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    return Caretaker(
      id: doc.id,
      name: data['name'] ?? 'Professional',
      email: data['email'],
      bio: data['bio'],
      specialties: List<String>.from(data['specialties'] ?? []),
      price: parseDouble(data['price'], 0.0),
      serviceFees: (data['serviceFees'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, parseDouble(value, 0.0)),
          ) ??
          {},
      rating: parseDouble(data['rating'], 5.0),
      isVerified: data['isVerified'] ?? false,
      profileUrl: data['profileUrl'],
      phoneNumber: data['phoneNumber'],
      latitude: parseDouble(data['latitude'], 0.0) == 0.0
          ? null
          : parseDouble(data['latitude'], 0.0),
      longitude: parseDouble(data['longitude'], 0.0) == 0.0
          ? null
          : parseDouble(data['longitude'], 0.0),
      isAvailable: data['isAvailable'] ?? true, // Default to true if missing
    );
  }
}

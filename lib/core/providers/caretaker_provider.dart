import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/core/repositories/caretaker_repository.dart';

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
    );
  }
}

final caretakerRepositoryProvider = Provider<ICaretakerRepository>((ref) {
  return CaretakerRepository();
});

final caretakerStreamProvider = StreamProvider<List<Caretaker>>((ref) {
  return ref.watch(caretakerRepositoryProvider).caretakersStream;
});

final singleCaretakerProvider =
    StreamProvider.family<Caretaker?, String>((ref, id) {
  return ref.watch(caretakerRepositoryProvider).getCaretakerStream(id);
});

// Optimized provider for proximity-based sorting
// This prevents expensive calculations inside the UI build methods
final nearbyCaretakersProvider =
    Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final caretakersAsync = ref.watch(caretakerStreamProvider);
  final authState = ref.watch(authProvider);

  return caretakersAsync.whenData((caretakers) {
    final user = authState is AuthAuthenticated ? authState.user : null;

    final caretakersWithDist = caretakers.map((c) {
      double? distInKm;
      if (user != null &&
          user.latitude != null &&
          user.longitude != null &&
          c.latitude != null &&
          c.longitude != null) {
        // Haversine calculation
        double meters = Geolocator.distanceBetween(
            user.latitude!, user.longitude!, c.latitude!, c.longitude!);
        distInKm = meters / 1000;
      }
      return {'caretaker': c, 'distance': distInKm};
    }).toList();

    // Sort: Nearby first, items without distance last
    caretakersWithDist.sort((a, b) {
      if (a['distance'] == null) return 1;
      if (b['distance'] == null) return -1;
      return (a['distance'] as double).compareTo(b['distance'] as double);
    });

    return caretakersWithDist;
  });
});

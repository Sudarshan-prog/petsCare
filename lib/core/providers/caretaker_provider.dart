import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Caretaker {
  final String id;
  final String name;
  final String? email;
  final String? bio;
  final List<String> specialties;
  final String price;
  final String rating;
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
    this.rating = '5.0',
    this.isVerified = false,
    this.profileUrl,
    this.phoneNumber,
    this.latitude,
    this.longitude,
  });

  factory Caretaker.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Caretaker(
      id: doc.id,
      name: data['name'] ?? 'Professional',
      email: data['email'],
      bio: data['bio'],
      specialties: List<String>.from(data['specialties'] ?? []),
      price: data['price'] ?? '0',
      rating: data['rating'] ?? '5.0',
      isVerified: data['isVerified'] ?? false,
      profileUrl: data['profileUrl'],
      phoneNumber: data['phoneNumber'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }
}

final caretakerStreamProvider = StreamProvider<List<Caretaker>>((ref) {
  return FirebaseFirestore.instance.collection('caretakers').snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Caretaker.fromFirestore(doc)).toList());
});

final singleCaretakerProvider =
    StreamProvider.family<Caretaker?, String>((ref, id) {
  return FirebaseFirestore.instance
      .collection('caretakers')
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? Caretaker.fromFirestore(doc) : null);
});

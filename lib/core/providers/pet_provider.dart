import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/auth/auth_provider.dart';

class Pet {
  final String id;
  final String ownerId;
  final String name;
  final String type;
  final String breed;
  final String age;

  Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
  });

  factory Pet.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Pet(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      breed: data['breed'] ?? '',
      age: data['age'] ?? '',
    );
  }
}

final userPetsProvider = StreamProvider<List<Pet>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return FirebaseFirestore.instance
        .collection('pets')
        .where('ownerId', isEqualTo: authState.user.id)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Pet.fromFirestore(doc)).toList());
  }
  return Stream.value([]);
});

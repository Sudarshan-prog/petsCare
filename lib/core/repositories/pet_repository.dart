import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carebridge/core/providers/pet_provider.dart';

abstract class IPetRepository {
  Stream<List<Pet>> getUserPets(String ownerId);
  Future<void> addPet(Pet pet);
}

class PetRepository implements IPetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Pet>> getUserPets(String ownerId) {
    return _firestore
        .collection('pets')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Pet.fromFirestore(doc)).toList());
  }

  @override
  Future<void> addPet(Pet pet) {
    return _firestore.collection('pets').add({
      'ownerId': pet.ownerId,
      'name': pet.name,
      'type': pet.type,
      'breed': pet.breed,
      'age': pet.age,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

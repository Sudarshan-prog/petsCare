import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:carebridge/core/exceptions/app_exception.dart';
import 'package:carebridge/models/pet.dart';

abstract class IPetRepository {
  Stream<List<Pet>> getUserPets(String ownerId);
  Future<void> addPet(Pet pet);
  Future<void> updatePet(String petId, Map<String, dynamic> data);
  Future<void> deletePet(String petId);
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
            snapshot.docs.map((doc) => Pet.fromFirestore(doc)).toList())
        .handleError((error) {
      debugPrint('❌ Error fetching pets for $ownerId: $error');
    });
  }

  @override
  Future<void> addPet(Pet pet) async {
    try {
      await _firestore.collection('pets').add({
        'ownerId': pet.ownerId,
        'name': pet.name,
        'type': pet.type,
        'breed': pet.breed,
        'age': pet.age,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AppException('Failed to add pet: ${e.message}',
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Unexpected error adding pet: $e',
          originalError: e);
    }
  }

  @override
  Future<void> updatePet(String petId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('pets').doc(petId).update(data);
    } on FirebaseException catch (e) {
      throw AppException('Failed to update pet: ${e.message}',
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Unexpected error updating pet: $e',
          originalError: e);
    }
  }

  @override
  Future<void> deletePet(String petId) async {
    try {
      await _firestore.collection('pets').doc(petId).delete();
    } on FirebaseException catch (e) {
      throw AppException('Failed to delete pet: ${e.message}',
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Unexpected error deleting pet: $e',
          originalError: e);
    }
  }
}

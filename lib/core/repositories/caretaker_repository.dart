import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:carebridge/core/providers/caretaker_provider.dart';

abstract class ICaretakerRepository {
  Stream<List<Caretaker>> get caretakersStream;
  Stream<Caretaker?> getCaretakerStream(String id);
  Future<void> saveCaretakerProfile(String uid, Map<String, dynamic> data);
  Future<void> updateCaretakerRating(String uid, double newRating);
}

class CaretakerRepository implements ICaretakerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Caretaker>> get caretakersStream {
    return _firestore.collection('caretakers').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Caretaker.fromFirestore(doc)).toList());
  }

  @override
  Stream<Caretaker?> getCaretakerStream(String id) {
    return _firestore
        .collection('caretakers')
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Caretaker.fromFirestore(doc) : null);
  }

  @override
  Future<void> saveCaretakerProfile(String uid, Map<String, dynamic> data) {
    return _firestore.collection('caretakers').doc(uid).set(
      {
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> updateCaretakerRating(String uid, double newRating) async {
    final docRef = _firestore.collection('caretakers').doc(uid);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        debugPrint("❌ ARCHITECT: ERROR - Caretaker doc $uid does not exist!");
        return;
      }

      final data = snapshot.data()!;
      final double currentRating = (data['rating'] as num?)?.toDouble() ?? 5.0;
      final int currentReviewCount =
          (data['reviewCount'] as num?)?.toInt() ?? 0;

      final int newReviewCount = currentReviewCount + 1;
      // Calculate running average: (currentAvg * count + newRating) / (count + 1)
      final double updatedAverage =
          ((currentRating * currentReviewCount) + newRating) / newReviewCount;

      transaction.update(docRef, {
        'rating': updatedAverage,
        'reviewCount': newReviewCount,
      });
    });
  }
}

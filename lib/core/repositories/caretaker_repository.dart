import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:carebridge/core/exceptions/app_exception.dart';
import 'package:carebridge/models/caretaker.dart';

abstract class ICaretakerRepository {
  Stream<List<Caretaker>> caretakersStream({int limit = 50});
  Stream<Caretaker?> getCaretakerStream(String id);
  Future<void> saveCaretakerProfile(String uid, Map<String, dynamic> data);
  Future<void> updateCaretakerAvailability(String uid, bool isAvailable);
  Future<void> updateCaretakerRating(String uid, double newRating);
}

class CaretakerRepository implements ICaretakerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Caretaker>> caretakersStream({int limit = 50}) {
    return _firestore
        .collection('caretakers')
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Caretaker.fromFirestore(doc)).toList())
        .handleError((error) {
      debugPrint('❌ Error fetching caretakers: $error');
    });
  }

  @override
  Stream<Caretaker?> getCaretakerStream(String id) {
    return _firestore
        .collection('caretakers')
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Caretaker.fromFirestore(doc) : null)
        .handleError((error) {
      debugPrint('❌ Error fetching caretaker $id: $error');
    });
  }

  @override
  Future<void> saveCaretakerProfile(
      String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('caretakers').doc(uid).set(
        {
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw AppException('Failed to save caretaker profile: ${e.message}',
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Unexpected error saving profile: $e',
          originalError: e);
    }
  }

  @override
  Future<void> updateCaretakerAvailability(String uid, bool isAvailable) async {
    try {
      await _firestore.collection('caretakers').doc(uid).update({
        'isAvailable': isAvailable,
      });
    } on FirebaseException catch (e) {
      throw AppException('Failed to update availability: ${e.message}',
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Unexpected error updating availability: $e',
          originalError: e);
    }
  }

  @override
  Future<void> updateCaretakerRating(String uid, double newRating) async {
    try {
      final docRef = _firestore.collection('caretakers').doc(uid);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw AppException('Caretaker not found',
              code: 'not-found');
        }

        final data = snapshot.data()!;
        final double currentRating =
            (data['rating'] as num?)?.toDouble() ?? 5.0;
        final int currentReviewCount =
            (data['reviewCount'] as num?)?.toInt() ?? 0;

        final int newReviewCount = currentReviewCount + 1;
        final double updatedAverage =
            ((currentRating * currentReviewCount) + newRating) / newReviewCount;

        transaction.update(docRef, {
          'rating': updatedAverage,
          'reviewCount': newReviewCount,
        });
      });
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw AppException('Failed to update rating: ${e.message}',
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Unexpected error updating rating: $e',
          originalError: e);
    }
  }
}

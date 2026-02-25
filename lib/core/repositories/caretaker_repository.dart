import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carebridge/core/providers/caretaker_provider.dart';

abstract class ICaretakerRepository {
  Stream<List<Caretaker>> get caretakersStream;
  Stream<Caretaker?> getCaretakerStream(String id);
  Future<void> saveCaretakerProfile(String uid, Map<String, dynamic> data);
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
}

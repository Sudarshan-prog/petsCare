import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class IStorageRepository {
  Future<String> uploadProfileImage(String userId, File file);
  Future<String> uploadBookingUpdate(String bookingId, File file);
  Future<void> deleteImage(String url);
}

class StorageRepository implements IStorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  StorageRepository() {
    debugPrint(
        "🏗️ ARCHITECT: Storage Initialized for bucket: ${_storage.bucket}");
  }

  @override
  Future<String> uploadProfileImage(String userId, File file) async {
    final ref = _storage.ref().child('profiles').child('$userId.jpg');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  @override
  Future<String> uploadBookingUpdate(String bookingId, File file) async {
    // ARCHITECT GUARD: Verify file exists
    if (!await file.exists()) {
      throw Exception("The captured photo file does not exist at ${file.path}");
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref =
        _storage.ref().child('bookings').child(bookingId).child(fileName);

    final fileSizeKBs = (await file.length()) / 1024;
    debugPrint("📂 ARCHITECT: Uploading Path: ${ref.fullPath}");
    debugPrint(
        "📊 ARCHITECT: Using ${fileSizeKBs.toStringAsFixed(2)} KB of your 10GB Bandwidth Free Tier.");

    try {
      // Adding explicit content type metadata helps bypass some bucket parsing errors
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      debugPrint("🔥 ARCHITECT STORAGE ERROR [${e.code}]: ${e.message}");
      rethrow;
    }
  }

  @override
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Log error but don't crash the app
      print('Error deleting image: $e');
    }
  }
}

final storageRepositoryProvider = Provider<IStorageRepository>((ref) {
  return StorageRepository();
});

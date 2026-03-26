import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/exceptions/app_exception.dart';

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
    try {
      final ref = _storage.ref().child('profiles').child('$userId.jpg');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw AppException('Failed to upload profile image: ${e.message}',
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Unexpected error uploading image: $e',
          originalError: e);
    }
  }

  @override
  Future<String> uploadBookingUpdate(String bookingId, File file) async {
    // ARCHITECT GUARD: Verify file exists
    if (!await file.exists()) {
      throw AppException(
          "The captured photo file does not exist at ${file.path}",
          code: 'file-not-found');
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref =
        _storage.ref().child('bookings').child(bookingId).child(fileName);

    final fileSizeKBs = (await file.length()) / 1024;
    debugPrint("📂 ARCHITECT: Uploading Path: ${ref.fullPath}");
    debugPrint(
        "📊 ARCHITECT: Using ${fileSizeKBs.toStringAsFixed(2)} KB of your 10GB Bandwidth Free Tier.");

    try {
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      throw AppException('Failed to upload booking photo: ${e.message}',
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Unexpected error uploading photo: $e',
          originalError: e);
    }
  }

  @override
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } on FirebaseException catch (e) {
      // Log but don't crash — image deletion is non-critical
      debugPrint('⚠️ Image deletion failed [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('⚠️ Error deleting image: $e');
    }
  }
}

final storageRepositoryProvider = Provider<IStorageRepository>((ref) {
  return StorageRepository();
});

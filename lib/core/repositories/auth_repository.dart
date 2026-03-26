import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:carebridge/models/app_user.dart';
import 'package:carebridge/core/exceptions/app_exception.dart';

abstract class IAuthRepository {
  Stream<User?> get authStateChanges;
  Future<AppUser?> getUserData(String uid);
  Future<UserCredential> login(String email, String password);
  Future<UserCredential> signup(String name, String email, String password);
  Future<void> updateUserData(String uid, Map<String, dynamic> data);
  Future<UserCredential?> loginWithGoogle();
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
  });
  Future<void> verifyOTPAndLink({
    required String verificationId,
    required String smsCode,
  });
  Future<void> logout();
  Future<void> deleteAccount();
}

class AuthRepository implements IAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<AppUser?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return AppUser(
        id: uid,
        name: data['name'] ?? 'User',
        email: data['email'] ?? '',
        profileUrl: data['profileUrl'],
        role: data['role'],
        phoneNumber: data['phoneNumber'],
        latitude: (data['latitude'] as num?)?.toDouble(),
        longitude: (data['longitude'] as num?)?.toDouble(),
      );
    } on FirebaseException catch (e) {
      throw AppException('Failed to fetch user data: ${e.message}',
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Unexpected error fetching user: $e',
          originalError: e);
    }
  }

  @override
  Future<UserCredential> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AppException(_authErrorMessage(e.code),
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Login failed: $e', originalError: e);
    }
  }

  @override
  Future<UserCredential> signup(
      String name, String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await credential.user?.updateDisplayName(name);

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'id': credential.user!.uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AppException(_authErrorMessage(e.code),
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Signup failed: $e', originalError: e);
    }
  }

  @override
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } on FirebaseException catch (e) {
      throw AppException('Failed to update profile: ${e.message}',
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Unexpected error updating profile: $e',
          originalError: e);
    }
  }

  @override
  Future<UserCredential?> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (!userDoc.exists) {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'id': userCredential.user!.uid,
          'name': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'profileUrl': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw AppException(_authErrorMessage(e.code),
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Google sign-in failed: $e', originalError: e);
    }
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
  }) async {
    // PHASE 0 SECURITY: Simulation ONLY in debug builds
    if (kDebugMode) {
      debugPrint('⚠️ DEBUG ONLY: Phone Auth Simulation Mode Active...');
      await Future.delayed(const Duration(seconds: 1));
      onCodeSent('demo_verify_id_${DateTime.now().millisecondsSinceEpoch}', 0);
      return;
    }

    // PRODUCTION: Real Firebase Phone Authentication
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.currentUser?.linkWithCredential(credential);
      },
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('Phone auth auto-retrieval timeout: $verificationId');
      },
      timeout: const Duration(seconds: 60),
    );
  }

  @override
  Future<void> verifyOTPAndLink({
    required String verificationId,
    required String smsCode,
  }) async {
    // PHASE 0 SECURITY: Simulation bypass ONLY in debug builds
    if (kDebugMode &&
        (smsCode == '123456' || verificationId.startsWith('demo_verify'))) {
      debugPrint('⚠️ DEBUG ONLY: Phone verified via local bypass.');
      return;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.currentUser?.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AppException(_authErrorMessage(e.code),
          code: e.code, originalError: e);
    } catch (e) {
      throw AppException('OTP verification failed: $e', originalError: e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('⚠️ Logout error (non-critical): $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('deleteAccount');
      await callable.call();
      
      // The Firebase backend function performs the full deletion (Firestore, Storage, Auth).
      // We also sign out locally just to clear the local session state completely.
      await _googleSignIn.signOut();
      await _auth.signOut();
    } on FirebaseFunctionsException catch (e) {
      throw AppException(e.message ?? 'Server error deleting account', code: e.code);
    } catch (e) {
      throw AppException('Failed to initiate account deletion: $e', originalError: e);
    }
  }

  /// Translates Firebase Auth error codes into user-friendly messages
  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:carebridge/core/auth/auth_provider.dart';

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
}

class AuthRepository implements IAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<AppUser?> getUserData(String uid) async {
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
  }

  @override
  Future<UserCredential> login(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential> signup(
      String name, String email, String password) async {
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
  }

  @override
  Future<void> updateUserData(String uid, Map<String, dynamic> data) {
    return _firestore.collection('users').doc(uid).update(data);
  }

  @override
  Future<UserCredential?> loginWithGoogle() async {
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
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'id': userCredential.user!.uid,
        'name': userCredential.user!.displayName,
        'email': userCredential.user!.email,
        'profileUrl': userCredential.user!.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return userCredential;
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
        // Auto-verification on some Android devices
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

    // PRODUCTION: Real OTP verification and account linking
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.currentUser?.linkWithCredential(credential);
  }

  @override
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

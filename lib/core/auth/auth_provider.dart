import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// 1. Data Model
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? profileUrl;
  final String? role; // 'owner' or 'caretaker'

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.profileUrl,
    this.role,
  });

  factory AppUser.fromFirebase(User user, {String? role}) {
    return AppUser(
      id: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
      profileUrl: user.photoURL,
      role: role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileUrl': profileUrl,
      'role': role,
    };
  }
}

// 2. Auth State
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final AppUser user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// 3. Notifier Logic
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthNotifier() : super(AuthInitial()) {
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        state = AuthUnauthenticated();
      } else {
        try {
          // Fetch extra data from Firestore if available
          final doc = await _firestore.collection('users').doc(user.uid).get();
          final data = doc.data();
          final String? role = data != null ? data['role'] as String? : null;
          state = AuthAuthenticated(AppUser.fromFirebase(user, role: role));
        } catch (e) {
          // Fallback if firestore fails
          state = AuthAuthenticated(AppUser.fromFirebase(user));
        }
      }
    });
  }

  Future<void> login(String email, String password) async {
    state = AuthLoading();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      state = AuthError(e.message ?? 'Login failed');
    }
  }

  Future<void> signup(String name, String email, String password) async {
    state = AuthLoading();
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await credential.user?.updateDisplayName(name);

      // Initial Firestore Entry
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'id': credential.user!.uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      state = AuthAuthenticated(AppUser.fromFirebase(credential.user!));
    } on FirebaseAuthException catch (e) {
      state = AuthError(e.message ?? 'Signup failed');
    }
  }

  Future<void> saveUserRole(String role) async {
    final user = _auth.currentUser;
    debugPrint("AUTH_PROVIDER: Saving role locally -> $role");
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({'role': role});
        // Refresh state
        state = AuthAuthenticated(AppUser.fromFirebase(user, role: role));
      } catch (e) {
        debugPrint("Error saving role: $e");
      }
    }
  }

  Future<void> savePetProfile({
    required String name,
    required String type,
    required String breed,
    required String age,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('pets').add({
          'ownerId': user.uid,
          'name': name,
          'type': type,
          'breed': breed,
          'age': age,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Error saving pet: $e");
      }
    }
  }

  Future<void> saveCaretakerProfile({
    required String bio,
    required List<String> specialties,
    required String price,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('caretakers').doc(user.uid).set({
          'id': user.uid,
          'name': user.displayName,
          'email': user.email,
          'bio': bio,
          'specialties': specialties,
          'price': price,
          'rating': '5.0',
          'isVerifed': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Error saving caretaker: $e");
      }
    }
  }

  Future<void> loginWithOAuth(String provider) async {
    state = AuthLoading();
    try {
      if (provider == 'Google') {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          state = AuthUnauthenticated();
          return;
        }
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
      } else {
        state = const AuthError('Provider not supported yet');
      }
    } catch (e) {
      state = AuthError('$provider login failed');
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    state = AuthUnauthenticated();
  }
}

// 4. Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

import 'package:carebridge/core/repositories/auth_repository.dart';
import 'package:carebridge/core/repositories/pet_repository.dart';
import 'package:carebridge/core/repositories/caretaker_repository.dart';
import 'package:carebridge/core/providers/pet_provider.dart';
import 'package:carebridge/core/providers/caretaker_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/services/notification_service.dart';

// 1. Data Model
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? profileUrl;
  final String? role; // 'owner' or 'caretaker'
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.profileUrl,
    this.role,
    this.phoneNumber,
    this.latitude,
    this.longitude,
  });

  /// ARCHITECT: Returns either the stored profile URL or a dynamically generated DiceBear avatar.
  /// This ensures zero Firebase Storage usage for profile pictures.
  String get effectiveProfileUrl {
    if (profileUrl != null && profileUrl!.isNotEmpty) return profileUrl!;
    // generates a unique high-quality adventurer avatar based on the user's unique ID
    return 'https://api.dicebear.com/7.x/adventurer/png?seed=$id&backgroundColor=b6e3f4,c0aede,d1d4f9';
  }

  factory AppUser.fromFirebase(
    User user, {
    String? role,
    String? phoneNumber,
    double? latitude,
    double? longitude,
  }) {
    return AppUser(
      id: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
      profileUrl: user.photoURL,
      role: role,
      phoneNumber: phoneNumber,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileUrl': profileUrl,
      'role': role,
      'phoneNumber': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
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
  final IAuthRepository _authRepository;
  final IPetRepository _petRepository;
  final ICaretakerRepository _caretakerRepository;

  AuthNotifier(
    this._authRepository,
    this._petRepository,
    this._caretakerRepository,
  ) : super(AuthInitial()) {
    _authRepository.authStateChanges.listen((user) async {
      if (user == null) {
        state = AuthUnauthenticated();
      } else {
        try {
          final appUser = await _authRepository.getUserData(user.uid);
          state = AuthAuthenticated(appUser ?? AppUser.fromFirebase(user));
          // Bulletproof: Update FCM token for every new session
          NotificationService.updateTokenInFirestore();
        } catch (e) {
          state = AuthAuthenticated(AppUser.fromFirebase(user));
        }
      }
    });
  }

  Future<void> login(String email, String password) async {
    state = AuthLoading();
    try {
      await _authRepository.login(email, password);
    } on Exception catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signup(String name, String email, String password) async {
    state = AuthLoading();
    try {
      final credential = await _authRepository.signup(name, email, password);
      state = AuthAuthenticated(AppUser.fromFirebase(credential.user!));
    } on Exception catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> saveUserRole(String role) async {
    if (state is AuthAuthenticated) {
      final user = (state as AuthAuthenticated).user;
      try {
        await _authRepository.updateUserData(user.id, {'role': role});
        final updatedUser = await _authRepository.getUserData(user.id);
        if (updatedUser != null) state = AuthAuthenticated(updatedUser);
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
    if (state is AuthAuthenticated) {
      final user = (state as AuthAuthenticated).user;
      try {
        await _petRepository.addPet(Pet(
          id: '', // Firestore generates ID
          ownerId: user.id,
          name: name,
          type: type,
          breed: breed,
          age: age,
        ));
      } catch (e) {
        debugPrint("Error saving pet: $e");
      }
    }
  }

  Future<void> saveCaretakerProfile({
    required String bio,
    required List<String> specialties,
    required String price,
    required String phoneNumber,
    required double latitude,
    required double longitude,
    Map<String, double>? serviceFees,
    bool isVerified = false,
  }) async {
    if (state is AuthAuthenticated) {
      final user = (state as AuthAuthenticated).user;
      try {
        // Update User Doc via AuthRepository
        await _authRepository.updateUserData(user.id, {
          'phoneNumber': phoneNumber,
          'latitude': latitude,
          'longitude': longitude,
        });

        // Save Caretaker Profile via CaretakerRepository
        await _caretakerRepository.saveCaretakerProfile(user.id, {
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'bio': bio,
          'specialties': specialties,
          'price': double.tryParse(price) ?? 0.0,
          'phoneNumber': phoneNumber,
          'latitude': latitude,
          'longitude': longitude,
          'rating': 5.0,
          'isVerified': isVerified,
          'profileUrl': user.profileUrl,
          'serviceFees': serviceFees,
        });

        final updatedUser = await _authRepository.getUserData(user.id);
        if (updatedUser != null) state = AuthAuthenticated(updatedUser);
      } catch (e) {
        debugPrint("Error saving caretaker: $e");
      }
    }
  }

  Future<void> updateLocation(double lat, double lng) async {
    if (state is AuthAuthenticated) {
      final user = (state as AuthAuthenticated).user;
      try {
        await _authRepository.updateUserData(user.id, {
          'latitude': lat,
          'longitude': lng,
        });
        final updatedUser = await _authRepository.getUserData(user.id);
        if (updatedUser != null) state = AuthAuthenticated(updatedUser);
      } catch (e) {
        debugPrint("Error updating location: $e");
      }
    }
  }

  Future<void> loginWithOAuth(String provider) async {
    state = AuthLoading();
    try {
      if (provider == 'Google') {
        await _authRepository.loginWithGoogle();
      } else {
        state = const AuthError('Provider not supported yet');
      }
    } catch (e) {
      state = AuthError('$provider login failed');
    }
  }

  Future<void> sendOTP(
    String phoneNumber, {
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String message) onError,
  }) async {
    try {
      await _authRepository.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onVerificationFailed: (e) =>
            onError(e.message ?? 'Verification failed'),
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> verifyOTP(String verificationId, String smsCode) async {
    try {
      await _authRepository.verifyOTPAndLink(
        verificationId: verificationId,
        smsCode: smsCode,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = AuthUnauthenticated();
  }

  Future<void> updateProfile({
    required String name,
    required String phoneNumber,
    String? bio,
    double? price,
    List<String>? specialties,
    Map<String, double>? serviceFees,
  }) async {
    if (state is AuthAuthenticated) {
      final user = (state as AuthAuthenticated).user;
      try {
        // 1. Update Core User Data
        await _authRepository.updateUserData(user.id, {
          'name': name,
          'phoneNumber': phoneNumber,
        });

        // 2. If Caretaker, update the specialized profile
        if (user.role == 'caretaker') {
          await _caretakerRepository.saveCaretakerProfile(user.id, {
            'name': name,
            'phoneNumber': phoneNumber,
            if (bio != null) 'bio': bio,
            if (price != null) 'price': price,
            if (specialties != null) 'specialties': specialties,
            if (serviceFees != null) 'serviceFees': serviceFees,
          });
        }

        // 3. Refresh Local State
        final updatedUser = await _authRepository.getUserData(user.id);
        if (updatedUser != null) state = AuthAuthenticated(updatedUser);
      } catch (e) {
        debugPrint("❌ ARCHITECT: Profile Update Failed: $e");
      }
    }
  }
}

// 4. Providers
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository();
});

final petRepositoryProvider = Provider<IPetRepository>((ref) {
  return PetRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final petRepo = ref.watch(petRepositoryProvider);
  final caretakerRepo = ref.watch(caretakerRepositoryProvider);
  return AuthNotifier(authRepo, petRepo, caretakerRepo);
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

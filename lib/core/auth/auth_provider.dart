import 'package:carebridge/core/repositories/auth_repository.dart';
import 'package:carebridge/core/repositories/pet_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/services/notification_service.dart';

// Re-export models so existing imports keep working
export 'package:carebridge/models/app_user.dart';
export 'package:carebridge/models/auth_state.dart';

// Import for internal use
import 'package:carebridge/models/app_user.dart';
import 'package:carebridge/models/auth_state.dart';

// AuthNotifier Logic
class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository _authRepository;
  
  AuthNotifier(
    this._authRepository,
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

  /// Exposed for ProfileNotifier to trigger state updates after modifying the user doc
  void refreshUser(AppUser updatedUser) {
    state = AuthAuthenticated(updatedUser);
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

  Future<void> deleteAccount() async {
    state = AuthLoading();
    try {
      await _authRepository.deleteAccount();
      state = AuthUnauthenticated();
    } catch (e) {
      state = AuthError('Failed to delete account: $e');
      rethrow; // Pass error to UI so user knows it failed
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
  return AuthNotifier(authRepo);
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

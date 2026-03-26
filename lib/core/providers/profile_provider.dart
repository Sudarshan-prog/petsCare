import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/models/app_user.dart';
import 'package:carebridge/models/pet.dart';
import 'package:carebridge/core/providers/caretaker_provider.dart';

class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ProfileNotifier(this._ref) : super(const AsyncValue.data(null));

  AppUser? _getUser() {
    final state = _ref.read(authProvider);
    if (state is AuthAuthenticated) {
      return state.user;
    }
    return null;
  }

  Future<void> saveUserRole(String role) async {
    final user = _getUser();
    if (user != null) {
      state = const AsyncValue.loading();
      try {
        await _ref.read(authRepositoryProvider).updateUserData(user.id, {'role': role});
        // Important: Update the Auth State to reflect the new role
        final updatedUser = await _ref.read(authRepositoryProvider).getUserData(user.id);
        if (updatedUser != null) {
          _ref.read(authProvider.notifier).refreshUser(updatedUser);
        }
        state = const AsyncValue.data(null);
      } catch (e, st) {
        debugPrint("Error saving role: $e");
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> savePetProfile({
    required String name,
    required String type,
    required String breed,
    required String age,
  }) async {
    final user = _getUser();
    if (user != null) {
      state = const AsyncValue.loading();
      try {
        await _ref.read(petRepositoryProvider).addPet(Pet(
          id: '',
          ownerId: user.id,
          name: name,
          type: type,
          breed: breed,
          age: age,
        ));
        state = const AsyncValue.data(null);
      } catch (e, st) {
        debugPrint("Error saving pet: $e");
        state = AsyncValue.error(e, st);
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
    final user = _getUser();
    if (user != null) {
      state = const AsyncValue.loading();
      try {
        await _ref.read(authRepositoryProvider).updateUserData(user.id, {
          'phoneNumber': phoneNumber,
          'latitude': latitude,
          'longitude': longitude,
        });

        await _ref.read(caretakerRepositoryProvider).saveCaretakerProfile(user.id, {
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

        final updatedUser = await _ref.read(authRepositoryProvider).getUserData(user.id);
        if (updatedUser != null) {
          _ref.read(authProvider.notifier).refreshUser(updatedUser);
        }
        state = const AsyncValue.data(null);
      } catch (e, st) {
        debugPrint("Error saving caretaker: $e");
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> updateLocation(double lat, double lng) async {
    final user = _getUser();
    if (user != null) {
      try {
        await _ref.read(authRepositoryProvider).updateUserData(user.id, {
          'latitude': lat,
          'longitude': lng,
        });
        final updatedUser = await _ref.read(authRepositoryProvider).getUserData(user.id);
        if (updatedUser != null) {
          _ref.read(authProvider.notifier).refreshUser(updatedUser);
        }
      } catch (e) {
        debugPrint("Error updating location: $e");
      }
    }
  }

  Future<void> updateProfile({
    required String name,
    required String phoneNumber,
    String? bio,
    double? price,
    List<String>? specialties,
    Map<String, double>? serviceFees,
  }) async {
    final user = _getUser();
    if (user != null) {
      state = const AsyncValue.loading();
      try {
        await _ref.read(authRepositoryProvider).updateUserData(user.id, {
          'name': name,
          'phoneNumber': phoneNumber,
        });

        if (user.role == 'caretaker') {
          await _ref.read(caretakerRepositoryProvider).saveCaretakerProfile(user.id, {
            'name': name,
            'phoneNumber': phoneNumber,
            if (bio != null) 'bio': bio,
            if (price != null) 'price': price,
            if (specialties != null) 'specialties': specialties,
            if (serviceFees != null) 'serviceFees': serviceFees,
          });
        }

        final updatedUser = await _ref.read(authRepositoryProvider).getUserData(user.id);
        if (updatedUser != null) {
          _ref.read(authProvider.notifier).refreshUser(updatedUser);
        }
        state = const AsyncValue.data(null);
      } catch (e, st) {
        debugPrint("❌ ARCHITECT: Profile Update Failed: $e");
        state = AsyncValue.error(e, st);
      }
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<void>>((ref) {
  return ProfileNotifier(ref);
});

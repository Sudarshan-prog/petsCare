import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/auth/auth_provider.dart';

// Re-export model so existing imports keep working
export 'package:carebridge/models/pet.dart';

// Import for internal use
import 'package:carebridge/models/pet.dart';

// 1. Data Provider (Stream)
final userPetsProvider = StreamProvider<List<Pet>>((ref) {
  final authState = ref.watch(authProvider);
  final petRepo = ref.watch(petRepositoryProvider);

  if (authState is AuthAuthenticated) {
    return petRepo.getUserPets(authState.user.id);
  }
  return Stream.value([]);
});

// 2. Action Notifier for CRUD
class PetNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  PetNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> addPet(
      String name, String type, String breed, String age) async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        await _ref.read(petRepositoryProvider).addPet(Pet(
              id: '',
              ownerId: authState.user.id,
              name: name,
              type: type,
              breed: breed,
              age: age,
            ));
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updatePet(String petId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(petRepositoryProvider).updatePet(petId, data);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deletePet(String petId) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(petRepositoryProvider).deletePet(petId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final petActionProvider =
    StateNotifierProvider<PetNotifier, AsyncValue<void>>((ref) {
  return PetNotifier(ref);
});

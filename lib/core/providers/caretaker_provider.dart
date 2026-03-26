import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/core/repositories/caretaker_repository.dart';

// Re-export model so existing imports keep working
export 'package:carebridge/models/caretaker.dart';

// Import for internal use
import 'package:carebridge/models/caretaker.dart';

final caretakerRepositoryProvider = Provider<ICaretakerRepository>((ref) {
  return CaretakerRepository();
});

final caretakerStreamProvider = StreamProvider<List<Caretaker>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return Stream.value([]);
  return ref.watch(caretakerRepositoryProvider).caretakersStream();
});

final singleCaretakerProvider = StreamProvider.family<Caretaker?, String>((ref, id) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return Stream.value(null);
  return ref.watch(caretakerRepositoryProvider).getCaretakerStream(id);
});

// Optimized provider for proximity-based sorting
// This prevents expensive calculations inside the UI build methods
final nearbyCaretakersProvider =
    Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final caretakersAsync = ref.watch(caretakerStreamProvider);
  final authState = ref.watch(authProvider);

  return caretakersAsync.whenData((caretakers) {
    final user = authState is AuthAuthenticated ? authState.user : null;

    final caretakersWithDist = caretakers.where((c) => c.isAvailable).map((c) {
      double? distInKm;
      if (user != null &&
          user.latitude != null &&
          user.longitude != null &&
          c.latitude != null &&
          c.longitude != null) {
        // Haversine calculation
        double meters = Geolocator.distanceBetween(
            user.latitude!, user.longitude!, c.latitude!, c.longitude!);
        distInKm = meters / 1000;
      }
      return {'caretaker': c, 'distance': distInKm};
    }).toList();

    // Sort: Nearby first, items without distance last
    caretakersWithDist.sort((a, b) {
      if (a['distance'] == null) return 1;
      if (b['distance'] == null) return -1;
      return (a['distance'] as double).compareTo(b['distance'] as double);
    });

    return caretakersWithDist;
  });
});

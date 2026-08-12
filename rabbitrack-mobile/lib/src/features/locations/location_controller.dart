import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'location_models.dart';
import 'location_repository.dart';

final locationListProvider =
    FutureProvider.autoDispose<List<FarmLocationSummary>>((ref) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        return [];
      }

      return ref.watch(locationRepositoryProvider).list(farm.id);
    });

final locationDetailProvider = FutureProvider.autoDispose
    .family<FarmLocationDetail, String>((ref, locationId) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        throw StateError('No selected farm.');
      }

      return ref
          .watch(locationRepositoryProvider)
          .show(farmId: farm.id, locationId: locationId);
    });

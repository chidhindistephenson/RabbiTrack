import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'mating_models.dart';
import 'mating_repository.dart';

final matingListProvider = FutureProvider.autoDispose<List<MatingSummary>>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;

  if (farm == null) {
    return [];
  }

  return ref.watch(matingRepositoryProvider).list(farm.id);
});

final rabbitMatingListProvider = FutureProvider.autoDispose
    .family<List<MatingSummary>, String>((ref, rabbitId) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        return [];
      }

      return ref
          .watch(matingRepositoryProvider)
          .list(farm.id, rabbitId: rabbitId);
    });

final matingDetailProvider = FutureProvider.autoDispose
    .family<MatingDetail, String>((ref, matingId) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        throw StateError('No selected farm.');
      }

      return ref
          .watch(matingRepositoryProvider)
          .show(farmId: farm.id, matingId: matingId);
    });

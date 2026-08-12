import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'weight_models.dart';
import 'weight_repository.dart';

final weightListProvider = FutureProvider.autoDispose<List<WeightSummary>>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;

  if (farm == null) {
    return [];
  }

  return ref.watch(weightRepositoryProvider).list(farm.id);
});

final rabbitWeightListProvider = FutureProvider.autoDispose
    .family<List<WeightSummary>, String>((ref, rabbitId) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        return [];
      }

      return ref
          .watch(weightRepositoryProvider)
          .list(farm.id, rabbitId: rabbitId);
    });

final litterWeightListProvider = FutureProvider.autoDispose
    .family<List<WeightSummary>, String>((ref, litterId) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        return [];
      }

      return ref
          .watch(weightRepositoryProvider)
          .list(farm.id, litterId: litterId);
    });

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'litter_models.dart';
import 'litter_repository.dart';

final litterListProvider = FutureProvider.autoDispose<List<LitterSummary>>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;

  if (farm == null) {
    return [];
  }

  return ref.watch(litterRepositoryProvider).list(farm.id);
});

final litterDetailProvider = FutureProvider.autoDispose
    .family<LitterDetail, String>((ref, litterId) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        throw StateError('No selected farm.');
      }

      return ref
          .watch(litterRepositoryProvider)
          .show(farmId: farm.id, litterId: litterId);
    });

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'health_models.dart';
import 'health_repository.dart';

final healthEventListProvider =
    FutureProvider.autoDispose<List<HealthEventSummary>>((ref) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        return [];
      }

      return ref.watch(healthRepositoryProvider).list(farm.id);
    });

final rabbitHealthEventListProvider = FutureProvider.autoDispose
    .family<List<HealthEventSummary>, String>((ref, rabbitId) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        return [];
      }

      return ref
          .watch(healthRepositoryProvider)
          .list(farm.id, rabbitId: rabbitId);
    });

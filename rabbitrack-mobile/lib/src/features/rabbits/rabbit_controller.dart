import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'rabbit_models.dart';
import 'rabbit_repository.dart';

class RabbitListFilters {
  const RabbitListFilters({this.search, this.sex, this.status, this.breed});

  final String? search;
  final String? sex;
  final String? status;
  final String? breed;

  RabbitListFilters copyWith({
    String? search,
    String? sex,
    String? status,
    String? breed,
    bool clearSearch = false,
    bool clearSex = false,
    bool clearStatus = false,
    bool clearBreed = false,
  }) {
    return RabbitListFilters(
      search: clearSearch ? null : search ?? this.search,
      sex: clearSex ? null : sex ?? this.sex,
      status: clearStatus ? null : status ?? this.status,
      breed: clearBreed ? null : breed ?? this.breed,
    );
  }
}

final rabbitListFiltersProvider = StateProvider.autoDispose<RabbitListFilters>(
  (ref) => const RabbitListFilters(),
);

final rabbitListProvider = FutureProvider.autoDispose<List<RabbitSummary>>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;
  final filters = ref.watch(rabbitListFiltersProvider);

  if (farm == null) {
    return [];
  }

  return ref
      .watch(rabbitRepositoryProvider)
      .list(
        farm.id,
        search: filters.search,
        sex: filters.sex,
        status: filters.status,
        breed: filters.breed,
      );
});

final rabbitDetailProvider = FutureProvider.autoDispose
    .family<RabbitDetail, String>((ref, rabbitId) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        throw StateError('No selected farm.');
      }

      return ref
          .watch(rabbitRepositoryProvider)
          .show(farmId: farm.id, rabbitId: rabbitId);
    });

final rabbitParentOptionsProvider =
    FutureProvider.autoDispose<List<RabbitSummary>>((ref) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        return [];
      }

      return ref.watch(rabbitRepositoryProvider).list(farm.id);
    });

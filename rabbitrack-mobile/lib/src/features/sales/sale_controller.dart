import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'sale_models.dart';
import 'sale_repository.dart';

final saleListProvider = FutureProvider.autoDispose<List<SaleSummary>>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;

  if (farm == null) {
    return [];
  }

  return ref.watch(saleRepositoryProvider).list(farm.id);
});

final rabbitSaleListProvider = FutureProvider.autoDispose
    .family<List<SaleSummary>, String>((ref, rabbitId) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        return [];
      }

      return ref
          .watch(saleRepositoryProvider)
          .list(farm.id, rabbitId: rabbitId);
    });

final saleReportProvider = FutureProvider.autoDispose<SaleReport>((ref) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;

  if (farm == null) {
    return const SaleReport(
      totalRevenue: '0.00',
      saleCount: 0,
      averageSale: '0.00',
      currency: 'USD',
    );
  }

  return ref.watch(saleRepositoryProvider).summary(farm.id);
});

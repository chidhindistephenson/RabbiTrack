import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'expense_models.dart';
import 'expense_repository.dart';

final expenseListProvider = FutureProvider.autoDispose<List<ExpenseSummary>>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;

  if (farm == null) {
    return [];
  }

  return ref.watch(expenseRepositoryProvider).list(farm.id);
});

final expenseReportProvider = FutureProvider.autoDispose<ExpenseReport>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;

  if (farm == null) {
    return const ExpenseReport(total: '0.00', currency: 'USD', byCategory: []);
  }

  return ref.watch(expenseRepositoryProvider).summary(farm.id);
});

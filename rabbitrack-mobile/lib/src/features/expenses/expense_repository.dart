import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../../shared/offline_demo_data.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'expense_models.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return ExpenseRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
    offlineQueue: ref.watch(offlineActionQueueProvider),
  );
});

class ExpenseRepository {
  const ExpenseRepository({
    required this.dio,
    required this.token,
    this.offlineQueue,
  });

  final Dio dio;
  final String? token;
  final OfflineActionQueue? offlineQueue;

  Future<List<ExpenseSummary>> list(String farmId) async {
    if (_isOfflineDemo) {
      return [
        if (isOfflineDemoFarm(farmId)) ...offlineDemoExpenses(),
        ...await _pendingOfflineExpenses(farmId),
      ];
    }

    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/expenses',
      options: _authOptions(),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map(
          (expense) => ExpenseSummary.fromJson(expense as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ExpenseReport> summary(String farmId) async {
    if (_isOfflineDemo) {
      final expenses = [
        if (isOfflineDemoFarm(farmId)) ...offlineDemoExpenses(),
        ...await _pendingOfflineExpenses(farmId),
      ];
      final total = expenses.fold<double>(
        0,
        (sum, expense) => sum + (double.tryParse(expense.amount) ?? 0),
      );
      final byCategory = <String, ({double total, int count})>{};
      for (final expense in expenses) {
        final current = byCategory[expense.category] ?? (total: 0, count: 0);
        byCategory[expense.category] = (
          total: current.total + (double.tryParse(expense.amount) ?? 0),
          count: current.count + 1,
        );
      }

      return ExpenseReport(
        total: total.toStringAsFixed(2),
        currency: 'USD',
        byCategory: byCategory.entries
            .map(
              (entry) => ExpenseCategoryTotal(
                category: entry.key,
                total: entry.value.total.toStringAsFixed(2),
                count: entry.value.count,
              ),
            )
            .toList(),
      );
    }

    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/expenses/summary',
      options: _authOptions(),
    );

    return ExpenseReport.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<ExpenseSummary> create({
    required String farmId,
    required String category,
    required double amount,
    required String spentOn,
    String? vendor,
    String? notes,
  }) async {
    final data = {
      'category': category,
      'spent_on': spentOn,
      'amount': amount,
      'vendor': vendor,
      'notes': notes,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/expenses',
        data: data,
        options: _authOptions(),
      );

      return ExpenseSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/expenses',
        data: data,
        headers: _authHeaders(),
      );

      return ExpenseSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        category: category,
        vendor: vendor,
        spentOn: spentOn,
        amount: amount.toStringAsFixed(2),
        currency: 'USD',
        notes: notes,
      );
    }
  }

  Options _authOptions() {
    return Options(headers: _authHeaders());
  }

  Map<String, dynamic> _authHeaders() {
    return {'Authorization': 'Bearer $token'};
  }

  bool get _isOfflineDemo => token?.startsWith('offline-demo-') == true;

  Future<List<ExpenseSummary>> _pendingOfflineExpenses(String farmId) async {
    final actions =
        await offlineQueue?.pendingActionsFor(
          method: 'POST',
          path: '/farms/$farmId/expenses',
        ) ??
        const [];

    return actions.map((action) {
      final data = action.data;

      return ExpenseSummary(
        id: 'local-${action.createdAt.microsecondsSinceEpoch}',
        category: data['category'] as String? ?? 'other',
        vendor: data['vendor'] as String?,
        spentOn: data['spent_on'] as String? ?? _dateValue(action.createdAt),
        amount: _money(data['amount']),
        currency: 'USD',
        notes: data['notes'] as String?,
      );
    }).toList();
  }

  String _money(Object? value) {
    if (value is num) {
      return value.toStringAsFixed(2);
    }

    return double.tryParse(value?.toString() ?? '')?.toStringAsFixed(2) ??
        '0.00';
  }

  String _dateValue(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

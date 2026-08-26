import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../../shared/offline_demo_data.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'sale_models.dart';

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return SaleRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
    offlineQueue: ref.watch(offlineActionQueueProvider),
  );
});

class SaleRepository {
  const SaleRepository({
    required this.dio,
    required this.token,
    this.offlineQueue,
  });

  final Dio dio;
  final String? token;
  final OfflineActionQueue? offlineQueue;

  Future<List<SaleSummary>> list(String farmId, {String? rabbitId}) async {
    if (_isOfflineDemo) {
      return [
        if (isOfflineDemoFarm(farmId)) ...offlineDemoSales(rabbitId: rabbitId),
        ...await _pendingOfflineSales(farmId, rabbitId: rabbitId),
      ];
    }

    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/sales',
      queryParameters: {'rabbit_id': ?rabbitId},
      options: _authOptions(),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map((sale) => SaleSummary.fromJson(sale as Map<String, dynamic>))
        .toList();
  }

  Future<SaleReport> summary(String farmId) async {
    if (_isOfflineDemo) {
      final sales = [
        if (isOfflineDemoFarm(farmId)) ...offlineDemoSales(),
        ...await _pendingOfflineSales(farmId),
      ];
      final total = sales.fold<double>(
        0,
        (sum, sale) => sum + (double.tryParse(sale.salePrice) ?? 0),
      );

      return SaleReport(
        totalRevenue: total.toStringAsFixed(2),
        saleCount: sales.length,
        averageSale: sales.isEmpty
            ? '0.00'
            : (total / sales.length).toStringAsFixed(2),
        currency: 'USD',
      );
    }

    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/sales/summary',
      options: _authOptions(),
    );

    return SaleReport.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<SaleSummary> create({
    required String farmId,
    required String rabbitId,
    required double salePrice,
    required String soldOn,
    String? buyerName,
    String? buyerPhone,
    String? notes,
  }) async {
    final data = {
      'rabbit_id': rabbitId,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'sold_on': soldOn,
      'sale_price': salePrice,
      'notes': notes,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/sales',
        data: data,
        options: _authOptions(),
      );

      return SaleSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/sales',
        data: data,
        headers: _authHeaders(),
      );

      return SaleSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        rabbitId: rabbitId,
        rabbitIdentifier: 'Pending rabbit',
        buyerName: buyerName,
        buyerPhone: buyerPhone,
        soldOn: soldOn,
        salePrice: salePrice.toStringAsFixed(2),
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

  Future<List<SaleSummary>> _pendingOfflineSales(
    String farmId, {
    String? rabbitId,
  }) async {
    final actions =
        await offlineQueue?.pendingActionsFor(
          method: 'POST',
          path: '/farms/$farmId/sales',
        ) ??
        const [];

    return actions
        .map((action) {
          final data = action.data;
          final localRabbitId =
              data['rabbit_id'] as String? ?? 'pending-rabbit';
          final rabbit = offlineDemoRabbitDetail(localRabbitId);

          return SaleSummary(
            id: 'local-${action.createdAt.microsecondsSinceEpoch}',
            rabbitId: localRabbitId,
            rabbitIdentifier: rabbit?.identifier ?? 'Pending rabbit',
            buyerName: data['buyer_name'] as String?,
            buyerPhone: data['buyer_phone'] as String?,
            soldOn: data['sold_on'] as String? ?? _dateValue(action.createdAt),
            salePrice: _money(data['sale_price']),
            currency: 'USD',
            notes: data['notes'] as String?,
          );
        })
        .where((sale) => rabbitId == null || sale.rabbitId == rabbitId)
        .toList();
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

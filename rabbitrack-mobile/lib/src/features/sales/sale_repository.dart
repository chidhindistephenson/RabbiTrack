import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
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
}

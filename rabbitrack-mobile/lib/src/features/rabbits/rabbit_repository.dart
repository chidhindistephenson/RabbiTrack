import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'rabbit_models.dart';

final rabbitRepositoryProvider = Provider<RabbitRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return RabbitRepository(dio: ref.watch(dioProvider), token: session?.token);
});

class RabbitRepository {
  const RabbitRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

  Future<List<RabbitSummary>> list(
    String farmId, {
    String? search,
    String? sex,
    String? status,
    String? breed,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/rabbits',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'sex': ?sex,
        'status': ?status,
        'breed': ?breed,
      },
      options: _authOptions(),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map((rabbit) => RabbitSummary.fromJson(rabbit as Map<String, dynamic>))
        .toList();
  }

  Future<RabbitSummary> create({
    required String farmId,
    required String sex,
    required String status,
    String? name,
    String? breed,
    String? colour,
    String? currentLocationId,
    String? dateOfBirth,
    String? weightValue,
    String? weightUnit,
    String? tagOrTattoo,
    String? notes,
    String? motherId,
    String? fatherId,
    String? originType,
    String? originLitterId,
    String? supplier,
    String? acquiredAt,
    String? acquisitionCost,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/rabbits',
      data: {
        'sex': sex,
        'status': status,
        'name': ?name,
        'breed': ?breed,
        'colour': ?colour,
        'current_location_id': ?currentLocationId,
        'date_of_birth': ?dateOfBirth,
        'weight_value': ?weightValue,
        'weight_unit': ?weightUnit,
        'tag_or_tattoo': ?tagOrTattoo,
        'notes': ?notes,
        'mother_id': ?motherId,
        'father_id': ?fatherId,
        'origin_type': ?originType,
        'origin_litter_id': ?originLitterId,
        'supplier': ?supplier,
        'acquired_at': ?acquiredAt,
        'acquisition_cost': ?acquisitionCost,
      },
      options: _authOptions(),
    );

    return RabbitSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<RabbitDetail> show({
    required String farmId,
    required String rabbitId,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/rabbits/$rabbitId',
      options: _authOptions(),
    );

    return RabbitDetail.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<RabbitMovementResult> move({
    required String farmId,
    required String rabbitId,
    required String toLocationId,
    String? reason,
    String? notes,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/rabbits/$rabbitId/movements',
      data: {'to_location_id': toLocationId, 'reason': reason, 'notes': notes},
      options: _authOptions(),
    );

    return RabbitMovementResult.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<RabbitSummary> updateStatus({
    required String farmId,
    required String rabbitId,
    required String status,
    String? notes,
  }) async {
    final response = await dio.patch<Map<String, dynamic>>(
      '/farms/$farmId/rabbits/$rabbitId',
      data: {'status': status, 'notes': ?notes},
      options: _authOptions(),
    );

    return RabbitSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<RabbitSummary> updateProfile({
    required String farmId,
    required String rabbitId,
    required String sex,
    required String status,
    String? name,
    String? breed,
    String? colour,
    String? currentLocationId,
    String? dateOfBirth,
    String? weightValue,
    String? weightUnit,
    String? tagOrTattoo,
    String? notes,
    String? motherId,
    String? fatherId,
  }) async {
    final response = await dio.patch<Map<String, dynamic>>(
      '/farms/$farmId/rabbits/$rabbitId',
      data: {
        'sex': sex,
        'status': status,
        'name': name,
        'breed': breed,
        'colour': colour,
        'current_location_id': currentLocationId,
        'date_of_birth': dateOfBirth,
        'weight_value': weightValue,
        'weight_unit': weightUnit,
        'tag_or_tattoo': tagOrTattoo,
        'notes': notes,
        'mother_id': motherId,
        'father_id': fatherId,
      },
      options: _authOptions(),
    );

    return RabbitSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Options _authOptions() {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}

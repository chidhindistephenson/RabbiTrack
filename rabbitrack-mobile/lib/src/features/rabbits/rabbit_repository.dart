import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../../shared/offline_demo_data.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'rabbit_models.dart';

final rabbitRepositoryProvider = Provider<RabbitRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return RabbitRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
    offlineQueue: ref.watch(offlineActionQueueProvider),
  );
});

class RabbitRepository {
  const RabbitRepository({
    required this.dio,
    required this.token,
    this.offlineQueue,
  });

  final Dio dio;
  final String? token;
  final OfflineActionQueue? offlineQueue;

  Future<List<RabbitSummary>> list(
    String farmId, {
    String? search,
    String? sex,
    String? status,
    String? breed,
  }) async {
    if (_isOfflineDemo) {
      return [
        if (isOfflineDemoFarm(farmId))
          ...offlineDemoRabbits(
            search: search,
            sex: sex,
            status: status,
            breed: breed,
          ),
        ...await _pendingOfflineRabbits(
          farmId,
          search: search,
          sex: sex,
          status: status,
          breed: breed,
        ),
      ];
    }

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
    final data = {
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
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/rabbits',
        data: data,
        options: _authOptions(),
      );

      return RabbitSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/rabbits',
        data: data,
        headers: _authHeaders(),
      );

      return RabbitSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        identifier: 'Pending ID',
        name: name,
        sex: sex,
        breed: breed,
        status: status,
      );
    }
  }

  Future<RabbitDetail> show({
    required String farmId,
    required String rabbitId,
  }) async {
    if (_isOfflineDemo) {
      final rabbit = await _offlineRabbitDetail(farmId, rabbitId);
      if (rabbit != null) {
        return rabbit;
      }
    }

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
    final data = {
      'to_location_id': toLocationId,
      'reason': reason,
      'notes': notes,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/rabbits/$rabbitId/movements',
        data: data,
        options: _authOptions(),
      );

      return RabbitMovementResult.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/rabbits/$rabbitId/movements',
        data: data,
        headers: _authHeaders(),
      );

      return RabbitMovementResult(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        rabbitId: rabbitId,
        toLocationId: toLocationId,
        movedAt: DateTime.now().toIso8601String(),
        reason: reason,
        notes: notes,
      );
    }
  }

  Future<RabbitSummary> updateStatus({
    required String farmId,
    required String rabbitId,
    required String status,
    String? notes,
  }) async {
    final data = {'status': status, 'notes': ?notes};

    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '/farms/$farmId/rabbits/$rabbitId',
        data: data,
        options: _authOptions(),
      );

      return RabbitSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'PATCH',
        path: '/farms/$farmId/rabbits/$rabbitId',
        data: data,
        headers: _authHeaders(),
      );

      return RabbitSummary(
        id: rabbitId,
        identifier: 'Pending update',
        sex: 'unknown',
        status: status,
      );
    }
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
    final data = {
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
    };

    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '/farms/$farmId/rabbits/$rabbitId',
        data: data,
        options: _authOptions(),
      );

      return RabbitSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'PATCH',
        path: '/farms/$farmId/rabbits/$rabbitId',
        data: data,
        headers: _authHeaders(),
      );

      return RabbitSummary(
        id: rabbitId,
        identifier: 'Pending update',
        name: name,
        sex: sex,
        breed: breed,
        status: status,
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

  Future<List<RabbitSummary>> _pendingOfflineRabbits(
    String farmId, {
    String? search,
    String? sex,
    String? status,
    String? breed,
  }) async {
    final actions =
        await offlineQueue?.pendingActionsFor(
          method: 'POST',
          path: '/farms/$farmId/rabbits',
        ) ??
        const [];
    final normalizedSearch = search?.trim().toLowerCase();

    return actions.map((action) => _summaryFromCreateAction(action)).where((
      rabbit,
    ) {
      final matchesSearch =
          normalizedSearch == null ||
          normalizedSearch.isEmpty ||
          [
            rabbit.identifier,
            rabbit.name,
            rabbit.breed,
            rabbit.currentLocationName,
          ].whereType<String>().any(
            (value) => value.toLowerCase().contains(normalizedSearch),
          );
      final matchesSex = sex == null || sex.isEmpty || rabbit.sex == sex;
      final matchesStatus =
          status == null || status.isEmpty || rabbit.status == status;
      final matchesBreed =
          breed == null || breed.isEmpty || rabbit.breed == breed;

      return matchesSearch && matchesSex && matchesStatus && matchesBreed;
    }).toList();
  }

  Future<RabbitDetail?> _offlineRabbitDetail(
    String farmId,
    String rabbitId,
  ) async {
    final created = await _pendingOfflineRabbitDetail(farmId, rabbitId);
    final starter = isOfflineDemoFarm(farmId)
        ? offlineDemoRabbitDetail(rabbitId)
        : null;
    final base = created ?? starter;
    if (base == null) {
      return null;
    }

    return _applyPendingRabbitActions(farmId, base);
  }

  Future<RabbitDetail?> _pendingOfflineRabbitDetail(
    String farmId,
    String rabbitId,
  ) async {
    final actions =
        await offlineQueue?.pendingActionsFor(
          method: 'POST',
          path: '/farms/$farmId/rabbits',
        ) ??
        const <QueuedOfflineAction>[];

    for (final action in actions) {
      final summary = _summaryFromCreateAction(action);
      if (summary.id != rabbitId) {
        continue;
      }

      final data = action.data;
      final locationId = data['current_location_id'] as String?;
      final location = locationId == null
          ? null
          : offlineDemoLocationDetail(locationId);
      final motherId = data['mother_id'] as String?;
      final fatherId = data['father_id'] as String?;
      final mother = motherId == null
          ? null
          : offlineDemoRabbitDetail(motherId);
      final father = fatherId == null
          ? null
          : offlineDemoRabbitDetail(fatherId);

      return RabbitDetail(
        id: summary.id,
        identifier: summary.identifier,
        name: summary.name,
        sex: summary.sex,
        status: summary.status,
        breed: summary.breed,
        dateOfBirth: summary.dateOfBirth,
        colour: data['colour'] as String?,
        currentLocationId: locationId,
        currentLocationName: location?.name,
        weightValue: data['weight_value'] as String?,
        weightUnit: data['weight_unit'] as String?,
        tagOrTattoo: data['tag_or_tattoo'] as String?,
        mother: mother == null
            ? null
            : RabbitParent(
                id: mother.id,
                identifier: mother.identifier,
                name: mother.name,
              ),
        father: father == null
            ? null
            : RabbitParent(
                id: father.id,
                identifier: father.identifier,
                name: father.name,
              ),
        movements: const [],
        notes: data['notes'] as String?,
      );
    }

    return null;
  }

  Future<RabbitDetail> _applyPendingRabbitActions(
    String farmId,
    RabbitDetail base,
  ) async {
    var current = base;

    final updates =
        await offlineQueue?.pendingActionsFor(
          method: 'PATCH',
          path: '/farms/$farmId/rabbits/${base.id}',
        ) ??
        const <QueuedOfflineAction>[];

    for (final action in updates) {
      current = _copyDetailWith(current, action.data);
    }

    final moves =
        await offlineQueue?.pendingActionsFor(
          method: 'POST',
          path: '/farms/$farmId/rabbits/${base.id}/movements',
        ) ??
        const <QueuedOfflineAction>[];

    for (final action in moves) {
      final locationId = action.data['to_location_id'] as String?;
      final location = locationId == null
          ? null
          : offlineDemoLocationDetail(locationId);
      current = RabbitDetail(
        id: current.id,
        identifier: current.identifier,
        sex: current.sex,
        status: current.status,
        movements: [
          ...current.movements,
          RabbitMovementSummary(
            id: 'local-${action.createdAt.microsecondsSinceEpoch}',
            fromLocation: current.currentLocationName,
            toLocation: location?.name ?? locationId,
            movedAt: action.createdAt.toIso8601String(),
            reason: action.data['reason'] as String?,
            notes: action.data['notes'] as String?,
          ),
        ],
        name: current.name,
        breed: current.breed,
        dateOfBirth: current.dateOfBirth,
        currentLocationId: locationId ?? current.currentLocationId,
        currentLocationName: location?.name ?? current.currentLocationName,
        colour: current.colour,
        weightValue: current.weightValue,
        weightUnit: current.weightUnit,
        tagOrTattoo: current.tagOrTattoo,
        mother: current.mother,
        father: current.father,
        notes: current.notes,
      );
    }

    return current;
  }

  RabbitDetail _copyDetailWith(
    RabbitDetail current,
    Map<String, dynamic> data,
  ) {
    return RabbitDetail(
      id: current.id,
      identifier: current.identifier,
      sex: data['sex'] as String? ?? current.sex,
      status: data['status'] as String? ?? current.status,
      movements: current.movements,
      name: data.containsKey('name') ? data['name'] as String? : current.name,
      breed: data.containsKey('breed')
          ? data['breed'] as String?
          : current.breed,
      dateOfBirth: data.containsKey('date_of_birth')
          ? data['date_of_birth'] as String?
          : current.dateOfBirth,
      currentLocationId: data.containsKey('current_location_id')
          ? data['current_location_id'] as String?
          : current.currentLocationId,
      currentLocationName: current.currentLocationName,
      colour: data.containsKey('colour')
          ? data['colour'] as String?
          : current.colour,
      weightValue: data.containsKey('weight_value')
          ? data['weight_value'] as String?
          : current.weightValue,
      weightUnit: data.containsKey('weight_unit')
          ? data['weight_unit'] as String?
          : current.weightUnit,
      tagOrTattoo: data.containsKey('tag_or_tattoo')
          ? data['tag_or_tattoo'] as String?
          : current.tagOrTattoo,
      mother: current.mother,
      father: current.father,
      notes: data.containsKey('notes')
          ? data['notes'] as String?
          : current.notes,
    );
  }

  RabbitSummary _summaryFromCreateAction(QueuedOfflineAction action) {
    final data = action.data;
    final localId = 'local-${action.createdAt.microsecondsSinceEpoch}';
    return RabbitSummary(
      id: localId,
      identifier:
          data['tag_or_tattoo'] as String? ?? _pendingIdentifier(localId),
      name: data['name'] as String?,
      sex: data['sex'] as String? ?? 'unknown',
      breed: data['breed'] as String?,
      dateOfBirth: data['date_of_birth'] as String?,
      status: data['status'] as String? ?? 'growing',
    );
  }

  String _pendingIdentifier(String localId) {
    return 'LOCAL-${localId.split('-').last.substring(0, 6)}';
  }
}

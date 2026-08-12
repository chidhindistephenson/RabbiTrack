import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_models.dart';
import 'auth_repository.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
      return AuthController(ref.watch(authRepositoryProvider));
    });

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController(this._repository) : super(const AsyncData(null)) {
    unawaited(restore());
  }

  final AuthRepository _repository;

  Future<void> restore() async {
    state = await AsyncValue.guard(_repository.restore);
  }

  Future<void> login({required String login, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.login(login: login, password: password),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String farmName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        farmName: farmName,
      ),
    );
  }

  Future<void> selectFarm(FarmSummary farm) async {
    final session = state.valueOrNull;
    if (session == null) {
      return;
    }

    await _repository.rememberSelectedFarm(farm.id);
    state = AsyncData(session.copyWith(selectedFarm: farm));
  }

  Future<void> addAndSelectFarm(FarmSummary farm) async {
    final session = state.valueOrNull;
    if (session == null) {
      return;
    }

    await _repository.rememberSelectedFarm(farm.id);
    state = AsyncData(
      session.copyWith(farms: [...session.farms, farm], selectedFarm: farm),
    );
  }

  void replaceFarm(FarmSummary farm) {
    final session = state.valueOrNull;
    if (session == null) {
      return;
    }

    state = AsyncData(
      session.copyWith(
        farms: [
          for (final existing in session.farms)
            existing.id == farm.id ? farm : existing,
        ],
        selectedFarm: session.selectedFarm?.id == farm.id
            ? farm
            : session.selectedFarm,
      ),
    );
  }

  Future<void> logout() async {
    await _repository.logout(state.valueOrNull?.token);
    state = const AsyncData(null);
  }
}

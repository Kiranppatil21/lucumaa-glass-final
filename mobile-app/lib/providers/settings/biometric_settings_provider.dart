import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../services/auth/biometric_auth_service.dart';
import '../../services/settings/biometric_settings_repository.dart';

final biometricSettingsRepositoryProvider = Provider<BiometricSettingsRepository>((ref) {
  return BiometricSettingsRepository();
});

final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService(ref.watch(localAuthProvider));
});

final biometricEnabledProvider = StateNotifierProvider<BiometricEnabledNotifier, AsyncValue<bool>>((ref) {
  return BiometricEnabledNotifier(ref.watch(biometricSettingsRepositoryProvider));
});

class BiometricEnabledNotifier extends StateNotifier<AsyncValue<bool>> {
  BiometricEnabledNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  final BiometricSettingsRepository _repo;

  Future<void> _load() async {
    final v = await _repo.isEnabled();
    state = AsyncValue.data(v);
  }

  Future<void> setEnabled(bool enabled) async {
    state = const AsyncValue.loading();
    await _repo.setEnabled(enabled);
    state = AsyncValue.data(enabled);
  }
}

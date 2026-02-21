import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../models/auth_tokens.dart';
import '../../models/user.dart';
import '../../services/auth/auth_repository.dart';
import '../../services/auth/biometric_auth_service.dart';
import '../../core/ui/snackbar_service.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(
    this._repo, {
    required BiometricAuthService biometricService,
    required Future<bool> Function() biometricEnabled,
    required SnackbarService snackbar,
  })  : _biometricService = biometricService,
        _biometricEnabled = biometricEnabled,
        _snackbar = snackbar,
        super(const AuthState.unknown());

  final AuthRepository _repo;
  final BiometricAuthService _biometricService;
  final Future<bool> Function() _biometricEnabled;
  final SnackbarService _snackbar;

  Future<AuthTokens?>? _refreshInFlight;

  bool _initialized = false;
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    final (tokens, user) = await _repo.loadFromStorage();
    if (tokens == null || user == null) {
      state = const AuthState.unauthenticated();
      return;
    }

    final bioEnabled = await _biometricEnabled();
    if (bioEnabled) {
      final ok = await _biometricService.authenticate(reason: 'Unlock Lucumaa Glass ERP');
      if (!ok) {
        state = const AuthState.unauthenticated('Biometric authentication failed');
        return;
      }
    }

    if (tokens.isExpired) {
      final refreshed = await _repo.refreshIfPossible(tokens);
      if (refreshed == null) {
        await logout();
        return;
      }
      final freshUser = await _repo.fetchMe();
      state = AuthState.authenticated(tokens: refreshed, user: freshUser ?? user);
      return;
    }

    // Use stored user immediately; then optionally refresh profile in background.
    state = AuthState.authenticated(tokens: tokens, user: user);
    final freshUser = await _repo.fetchMe();
    if (freshUser != null && mounted) {
      state = AuthState.authenticated(tokens: tokens, user: freshUser);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthState.unauthenticated();
    try {
      final (tokens, user) = await _repo.login(email: email, password: password);
      state = AuthState.authenticated(tokens: tokens, user: user);
    } catch (e) {
      final ex = AppException.fromDio(e);
      _snackbar.showMessage(ex.message);
      state = AuthState.unauthenticated(ex.message);
    }
  }

  Future<AuthTokens?> refreshTokens() async {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final completer = _doRefresh();
    _refreshInFlight = completer;
    try {
      return await completer;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<AuthTokens?> _doRefresh() async {
    final current = state.tokens;
    final refreshed = await _repo.refreshIfPossible(current);
    if (refreshed == null) return null;
    final user = state.user;
    if (user != null) {
      state = AuthState.authenticated(tokens: refreshed, user: user);
    }
    return refreshed;
  }

  Future<void> logout() async {
    await _repo.clear();
    state = const AuthState.unauthenticated();
  }

  User? get currentUser => state.user;
}

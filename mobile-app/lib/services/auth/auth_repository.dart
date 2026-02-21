import '../../core/network/app_exception.dart';
import '../../models/auth_tokens.dart';
import '../../models/user.dart';
import '../storage/secure_storage_service.dart';
import 'auth_api.dart';

class AuthRepository {
  AuthRepository({
    required AuthApi api,
    required SecureStorageService storage,
  })  : _api = api,
        _storage = storage;

  final AuthApi _api;
  final SecureStorageService _storage;

  Future<(AuthTokens, User)> login({required String email, required String password}) async {
    try {
      final tokens = await _api.login(email: email, password: password);
      if (tokens.accessToken.isEmpty) {
        throw const AppException('Login succeeded but token was not returned by server');
      }
      await _storage.saveTokens(tokens);

      final user = await _api.meWithToken(accessToken: tokens.accessToken);
      await _storage.saveUser(user);

      return (tokens, user);
    } catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<AuthTokens?> refreshIfPossible(AuthTokens? current) async {
    final refreshToken = current?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;
    try {
      final fresh = await _api.refresh(refreshToken: refreshToken);
      await _storage.saveTokens(fresh);
      return fresh;
    } catch (_) {
      return null;
    }
  }

  Future<(AuthTokens?, User?)> loadFromStorage() async {
    final tokens = await _storage.readTokens();
    final user = await _storage.readUser();
    return (tokens, user);
  }

  Future<User?> fetchMe() async {
    try {
      final tokens = await _storage.readTokens();
      final accessToken = tokens?.accessToken;
      if (accessToken == null || accessToken.isEmpty) return null;
      final user = await _api.meWithToken(accessToken: accessToken);
      await _storage.saveUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() => _storage.clearAll();
}

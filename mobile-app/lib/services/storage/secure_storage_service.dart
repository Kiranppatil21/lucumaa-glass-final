import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/auth_tokens.dart';
import '../../models/user.dart';

class SecureStorageService {
  static const _kTokens = 'auth_tokens_v1';
  static const _kUser = 'auth_user_v1';

  final FlutterSecureStorage _storage;

  const SecureStorageService(this._storage);

  Future<void> saveTokens(AuthTokens tokens) async {
    await _storage.write(key: _kTokens, value: jsonEncode(tokens.toJson()));
  }

  Future<AuthTokens?> readTokens() async {
    final raw = await _storage.read(key: _kTokens);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearTokens() => _storage.delete(key: _kTokens);

  Future<void> saveUser(User user) async {
    await _storage.write(key: _kUser, value: jsonEncode(user.toJson()));
  }

  Future<User?> readUser() async {
    final raw = await _storage.read(key: _kUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() => _storage.delete(key: _kUser);

  Future<void> clearAll() async {
    await clearTokens();
    await clearUser();
  }
}

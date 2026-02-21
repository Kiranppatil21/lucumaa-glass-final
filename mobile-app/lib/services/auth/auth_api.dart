import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../models/auth_tokens.dart';
import '../../models/user.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthTokens> login({required String email, required String password}) async {
    final resp = await _dio.post(
      AppConfig.loginPath,
      data: {
        'email': email,
        'password': password,
      },
    );
    final data = (resp.data is Map) ? resp.data as Map<String, dynamic> : <String, dynamic>{};
    return AuthTokens.fromJson(data);
  }

  Future<AuthTokens> refresh({required String refreshToken}) async {
    final resp = await _dio.post(
      AppConfig.refreshPath,
      data: {
        'refresh_token': refreshToken,
      },
    );
    final data = (resp.data is Map) ? resp.data as Map<String, dynamic> : <String, dynamic>{};
    return AuthTokens.fromJson(data);
  }

  Future<User> me() async {
    final resp = await _dio.get(AppConfig.mePath);
    final data = (resp.data is Map) ? resp.data as Map<String, dynamic> : <String, dynamic>{};
    final userJson = (data['data'] is Map) ? data['data'] as Map<String, dynamic> : data;
    return User.fromJson(userJson);
  }

  Future<User> meWithToken({required String accessToken}) async {
    final resp = await _dio.get(
      AppConfig.mePath,
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
    final data = (resp.data is Map) ? resp.data as Map<String, dynamic> : <String, dynamic>{};
    final userJson = (data['data'] is Map) ? data['data'] as Map<String, dynamic> : data;
    return User.fromJson(userJson);
  }
}

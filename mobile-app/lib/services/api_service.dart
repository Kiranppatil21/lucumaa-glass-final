import 'package:dio/dio.dart';

import '../core/network/app_exception.dart';

/// Thin wrapper around Dio providing consistent exception mapping.
class ApiService {
  ApiService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final resp = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _asJson(resp.data);
    } catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final resp = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _asJson(resp.data);
    } catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final resp = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _asJson(resp.data);
    } catch (e) {
      throw AppException.fromDio(e);
    }
  }

  static Map<String, dynamic> _asJson(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }
}

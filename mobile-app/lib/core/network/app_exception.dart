import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const AppException(this.message, {this.statusCode, this.code});

  factory AppException.fromDio(Object error) {
    if (error is AppException) return error;
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;

      // Special-case auth/login: show backend's real message (e.g. Invalid credentials)
      final path = error.requestOptions.path;
      final isLogin = path.contains('/auth/login');
      if (status == 401 && isLogin) {
        final msg = _extractMessage(data) ?? 'Invalid credentials';
        return AppException(msg, statusCode: status);
      }

      if (status == 401) {
        return const UnauthorizedException('Session expired. Please login again.');
      }

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return const OfflineException('No internet connection');
      }

      final msg = _extractMessage(data) ?? error.message ?? 'Network error';
      return AppException(msg, statusCode: status);
    }
    return AppException(error.toString());
  }

  static String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['msg'];
      if (message is String) return message;
      if (message is List && message.isNotEmpty) return message.first.toString();
    }
    return null;
  }
}

class OfflineException extends AppException {
  const OfflineException(super.message);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message);
}


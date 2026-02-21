import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/network/app_exception.dart';

class UploadService {
  UploadService(this._dio);
  final Dio _dio;

  Future<void> uploadWorkPhoto(File file) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last),
      });
      await _dio.post('/uploads', data: form);
    } catch (e) {
      throw AppException.fromDio(e);
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../../services/uploads/upload_service.dart';

final uploadServiceProvider = Provider<UploadService>((ref) {
  final Dio dio = ref.watch(authenticatedDioProvider);
  return UploadService(dio);
});

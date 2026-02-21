import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth/auth_providers.dart';
import '../../services/api_service.dart';
import '../../services/orders/orders_api.dart';
import '../../services/orders/orders_repository.dart';
import 'orders_notifier.dart';
import 'orders_state.dart';

final _ordersApiServiceProvider = Provider<ApiService>((ref) {
  final Dio dio = ref.watch(authenticatedDioProvider);
  return ApiService(dio);
});

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final apiService = ref.watch(_ordersApiServiceProvider);
  return OrdersRepository(OrdersApi(apiService));
});

final ordersNotifierProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final repo = ref.watch(ordersRepositoryProvider);
  return OrdersNotifier(repo);
});

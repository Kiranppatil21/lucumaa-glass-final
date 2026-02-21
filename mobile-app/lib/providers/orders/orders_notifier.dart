import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/app_exception.dart';
import '../../services/orders/orders_repository.dart';
import 'orders_state.dart';

class OrdersNotifier extends StateNotifier<OrdersState> {
  OrdersNotifier(this._repo) : super(OrdersState.initial()) {
    refresh();
  }

  final OrdersRepository _repo;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null, page: 0, hasMore: true, items: []);
    try {
      final page0 = await _repo.list(page: 0, pageSize: AppConfig.defaultPageSize);
      state = state.copyWith(
        isLoading: false,
        items: page0.items,
        page: 0,
        hasMore: page0.hasMore,
      );
    } catch (e) {
      final ex = AppException.fromDio(e);
      state = state.copyWith(isLoading: false, error: ex.message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, error: null);
    final nextPage = state.page + 1;
    try {
      final resp = await _repo.list(page: nextPage, pageSize: AppConfig.defaultPageSize);
      state = state.copyWith(
        isLoadingMore: false,
        page: nextPage,
        hasMore: resp.hasMore,
        items: [...state.items, ...resp.items],
      );
    } catch (e) {
      final ex = AppException.fromDio(e);
      state = state.copyWith(isLoadingMore: false, error: ex.message);
    }
  }
}

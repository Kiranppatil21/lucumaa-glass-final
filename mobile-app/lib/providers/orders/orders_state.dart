import '../../models/order.dart';

class OrdersState {
  final List<Order> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  const OrdersState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.page,
    this.error,
  });

  factory OrdersState.initial() => const OrdersState(
        items: [],
        isLoading: true,
        isLoadingMore: false,
        hasMore: true,
        page: 0,
      );

  OrdersState copyWith({
    List<Order>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return OrdersState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
    );
  }
}

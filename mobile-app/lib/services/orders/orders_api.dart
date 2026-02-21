import '../../models/order.dart';
import '../../models/paged_response.dart';
import '../api_service.dart';

class OrdersApi {
  OrdersApi(this._api);

  final ApiService _api;

  Future<PagedResponse<Order>> listOrders({required int page, required int pageSize}) async {
    final json = await _api.getJson(
      '/orders',
      queryParameters: {
        'page': page,
        'limit': pageSize,
      },
    );

    return PagedResponse.fromJson(
      json,
      page: page,
      pageSize: pageSize,
      itemFromJson: Order.fromJson,
    );
  }
}

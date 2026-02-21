import '../../core/config/app_config.dart';
import '../../core/network/app_exception.dart';
import '../../models/order.dart';
import '../../models/paged_response.dart';
import 'orders_api.dart';

class OrdersRepository {
  OrdersRepository(this._api);
  final OrdersApi _api;

  Future<PagedResponse<Order>> list({int page = 0, int pageSize = AppConfig.defaultPageSize}) async {
    try {
      return await _api.listOrders(page: page, pageSize: pageSize);
    } catch (e) {
      throw AppException.fromDio(e);
    }
  }
}

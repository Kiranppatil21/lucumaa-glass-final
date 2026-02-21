class PagedResponse<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final bool hasMore;

  const PagedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  static PagedResponse<T> fromJson<T>(
    Map<String, dynamic> json, {
    required int page,
    required int pageSize,
    required T Function(Map<String, dynamic>) itemFromJson,
  }) {
    final dynamic container = json['data'] ?? json;
    final dynamic listRaw = (container is Map) ? (container['items'] ?? container['data'] ?? container['results']) : container;
    final List<dynamic> list = listRaw is List ? listRaw : const [];
    final items = list.whereType<Map>().map((e) => itemFromJson(e.cast<String, dynamic>())).toList(growable: false);

    final totalRaw = (container is Map) ? (container['total'] ?? container['count']) : null;
    final total = (totalRaw is num) ? totalRaw.toInt() : null;
    final hasMore = total != null ? (page * pageSize + items.length) < total : items.length == pageSize;
    return PagedResponse(items: items, page: page, pageSize: pageSize, hasMore: hasMore);
  }
}

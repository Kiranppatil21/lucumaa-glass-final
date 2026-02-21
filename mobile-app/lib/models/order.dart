class Order {
  final String id;
  final String code;
  final String status;
  final DateTime? createdAt;

  const Order({
    required this.id,
    required this.code,
    required this.status,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: (json['id'] ?? json['order_id'] ?? '').toString(),
      code: (json['code'] ?? json['order_no'] ?? json['orderNumber'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? json['createdAt'] ?? '').toString()),
    );
  }
}

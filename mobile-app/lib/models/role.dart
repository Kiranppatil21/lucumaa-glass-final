enum Role {
  admin,
  manager,
  operator,
  sales,
  hr,
  dealer;

  static Role? fromApi(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim().toLowerCase();
    return switch (raw) {
      'admin' => Role.admin,
      'manager' => Role.manager,
      'operator' => Role.operator,
      'sales' => Role.sales,
      'hr' => Role.hr,
      'dealer' => Role.dealer,
      _ => null,
    };
  }

  String get apiValue => name;
}

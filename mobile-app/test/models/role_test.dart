import 'package:flutter_test/flutter_test.dart';
import 'package:lucumaa_glass_erp/models/role.dart';

void main() {
  test('Role.fromApi maps known roles', () {
    expect(Role.fromApi('Admin'), Role.admin);
    expect(Role.fromApi('dealer'), Role.dealer);
    expect(Role.fromApi('HR'), Role.hr);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lucumaa_glass_erp/providers/auth/login_form.dart';

void main() {
  group('LoginForm inputs', () {
    test('UsernameInput validates required', () {
      const u = EmailInput.dirty('');
      expect(u.isValid, isFalse);
      expect(u.error, isNotNull);
    });

    test('PasswordInput validates length', () {
      const p = PasswordInput.dirty('1');
      expect(p.isValid, isFalse);
    });

    test('Valid inputs pass', () {
      const u = EmailInput.dirty('admin@example.com');
      const p = PasswordInput.dirty('1234');
      expect(u.isValid, isTrue);
      expect(p.isValid, isTrue);
    });
  });
}

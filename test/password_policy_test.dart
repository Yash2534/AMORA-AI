import 'package:amora_ai/features/auth/domain/amora_password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new passwords use the shared eight-character requirement', () {
    expect(
      AmoraPasswordPolicy.validateNewPassword('1234567'),
      AmoraPasswordPolicy.requirement,
    );
    expect(AmoraPasswordPolicy.validateNewPassword('12345678'), isNull);
  });

  test('login only rejects missing passwords', () {
    expect(
      AmoraPasswordPolicy.validateLoginPassword(''),
      'Password is required',
    );
    expect(AmoraPasswordPolicy.validateLoginPassword('old'), isNull);
  });
}

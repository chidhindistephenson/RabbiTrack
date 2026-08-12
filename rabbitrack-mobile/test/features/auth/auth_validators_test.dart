import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/auth/auth_validators.dart';

void main() {
  test('auth validators return useful messages', () {
    expect(requiredTextValidator('', 'Required'), 'Required');
    expect(emailValidator('bad-email'), 'Enter a valid email');
    expect(emailValidator('owner@rabbitrack.local'), isNull);
    expect(passwordValidator('short'), 'Use at least 8 characters');
    expect(passwordValidator('secret-password'), isNull);
    expect(resetCodeValidator('12345'), 'Enter the 6-digit code');
    expect(resetCodeValidator('123456'), isNull);
    expect(confirmPasswordValidator('one', 'two'), 'Passwords do not match');
  });
}

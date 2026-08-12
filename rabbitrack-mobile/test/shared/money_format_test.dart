import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/shared/money_format.dart';

void main() {
  group('currencySymbol', () {
    test('uses dollar sign for USD', () {
      expect(currencySymbol('USD'), r'$');
      expect(currencySymbol('usd'), r'$');
    });

    test('keeps stale or unsupported currencies dollar-only', () {
      expect(currencySymbol('eur'), r'$');
      expect(currencySymbol('ZAR'), r'$');
    });
  });

  group('formatMoney', () {
    test('combines symbol and amount', () {
      expect(formatMoney('USD', '24.50'), r'$ 24.50');
    });
  });
}

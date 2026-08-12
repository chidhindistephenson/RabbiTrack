import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/farms/farm_currency_options.dart';

void main() {
  test('farmCurrencyLabel presents USD as dollar currency', () {
    expect(farmCurrencyLabel('USD'), r'US Dollar ($)');
    expect(farmCurrencyLabel('usd'), r'US Dollar ($)');
  });

  test('supportedFarmCurrencyOrDefault keeps farm setup dollar-only', () {
    expect(supportedFarmCurrencyOrDefault('USD'), 'USD');
    expect(supportedFarmCurrencyOrDefault(' usd '), 'USD');
    expect(supportedFarmCurrencyOrDefault('ZAR'), 'USD');
    expect(supportedFarmCurrencyOrDefault(''), 'USD');
  });
}

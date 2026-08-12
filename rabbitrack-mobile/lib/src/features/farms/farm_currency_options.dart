const defaultFarmCurrency = 'USD';

const supportedFarmCurrencies = [defaultFarmCurrency];

String farmCurrencyLabel(String currency) {
  return switch (currency.toUpperCase()) {
    'USD' => 'US Dollar (\$)',
    _ => currency.toUpperCase(),
  };
}

String supportedFarmCurrencyOrDefault(String currency) {
  final normalized = currency.trim().toUpperCase();

  return supportedFarmCurrencies.contains(normalized)
      ? normalized
      : defaultFarmCurrency;
}

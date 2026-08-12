String currencySymbol(String currency) {
  return switch (currency.toUpperCase()) {
    'USD' => r'$',
    _ => r'$',
  };
}

String formatMoney(String currency, Object amount) {
  return '${currencySymbol(currency)} $amount';
}

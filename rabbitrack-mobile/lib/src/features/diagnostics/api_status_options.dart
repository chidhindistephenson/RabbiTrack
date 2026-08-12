String apiCheckLabel(String key) {
  return switch (key) {
    'database' => 'Database',
    'redis' => 'Redis',
    'demo_account' => 'Demo account',
    _ => _sentenceCase(key),
  };
}

String apiBaseUrlMode(String baseUrl) {
  final host = Uri.tryParse(baseUrl)?.host ?? '';

  return switch (host) {
    '10.0.2.2' => 'Android emulator',
    '127.0.0.1' || 'localhost' => 'This device only',
    _ when _isLanHost(host) => 'Wireless device',
    _ => 'Custom endpoint',
  };
}

List<String> apiTroubleshootingSteps(String baseUrl) {
  final host = Uri.tryParse(baseUrl)?.host ?? '';

  if (host == '10.0.2.2') {
    return const [
      'Use this URL only on Android Studio emulators.',
      'For a physical phone, rebuild with your computer Wi-Fi IP.',
    ];
  }

  if (host == '127.0.0.1' || host == 'localhost') {
    return const [
      'This URL only works from the computer running Laravel.',
      'For a physical phone, use the wireless install script.',
    ];
  }

  if (_isLanHost(host)) {
    return const [
      'Confirm phone and computer are on the same Wi-Fi.',
      'Confirm Laravel is running on 0.0.0.0:8000.',
      'Confirm Windows Firewall allows TCP port 8000.',
    ];
  }

  return const [
    'Confirm the endpoint is reachable from this device.',
    'Confirm the API URL ends with /api/v1.',
  ];
}

String _sentenceCase(String value) {
  final words = value.split('_').where((part) => part.isNotEmpty).toList();

  if (words.isEmpty) {
    return value;
  }

  return [
    '${words.first[0].toUpperCase()}${words.first.substring(1)}',
    ...words.skip(1),
  ].join(' ');
}

bool _isLanHost(String host) {
  return host.startsWith('192.168.') ||
      host.startsWith('10.') ||
      RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(host);
}

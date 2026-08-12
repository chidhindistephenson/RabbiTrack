class ApiConfig {
  static const defaultBaseUrl = 'http://10.0.2.2:8000/api/v1';

  static const baseUrl = String.fromEnvironment(
    'RABBITRACK_API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );
}

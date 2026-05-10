class HubConfig {
  HubConfig._();

  /// Base URL for the local offline laptop hub Socket.IO server.
  ///
  /// Override at build/run time, e.g.
  /// `flutter run --dart-define=HUB_BASE_URL=http://192.168.1.50:3001`
  static const String baseUrl = String.fromEnvironment(
    'HUB_BASE_URL',
    defaultValue: 'http://192.168.137.1:3001',
  );
}

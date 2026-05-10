/// Cloud API base URL with **no trailing slash**.
///
/// Override at build/run time, e.g.
/// `flutter run --dart-define=API_BASE_URL=https://your-service.onrender.com`
///
/// - iOS Simulator / desktop talking to a server on the same machine: `http://127.0.0.1:3000`
/// - Android Emulator → host machine: `http://10.0.2.2:3000`
/// - Physical device → your laptop LAN IP, e.g. `http://192.168.1.42:3000`
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.137.1:3000',
  );
}

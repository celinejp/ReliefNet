/// Auth0 Native Application settings from `--dart-define` at compile time.
///
/// Example:
/// ```bash
/// flutter run --dart-define=AUTH0_DOMAIN=dev-xxx.us.auth0.com \
///   --dart-define=AUTH0_CLIENT_ID=xxxxx \
///   --dart-define=AUTH0_AUDIENCE=https://reliefnet-api \
///   --dart-define=AUTH0_SCHEME=reliefnet \
///   --dart-define=API_BASE_URL=http://127.0.0.1:3000
/// ```
///
/// Android: set `manifestPlaceholders.auth0Domain` in `android/app/build.gradle.kts`
/// to the same domain string so Universal Login can return to the app.
class Auth0Config {
  Auth0Config._();

  static const String domain = String.fromEnvironment(
    'AUTH0_DOMAIN',
    defaultValue: '',
  );

  static const String clientId = String.fromEnvironment(
    'AUTH0_CLIENT_ID',
    defaultValue: '',
  );

  /// ReliefNet API identifier (must match `AUTH0_AUDIENCE` on the Node server).
  static const String audience = String.fromEnvironment(
    'AUTH0_AUDIENCE',
    defaultValue: '',
  );

  /// URL scheme for iOS/Android callbacks (must match Auth0 Allowed Callback URLs).
  static const String scheme = String.fromEnvironment(
    'AUTH0_SCHEME',
    defaultValue: 'reliefnet',
  );

  static bool get isConfigured =>
      domain.isNotEmpty && clientId.isNotEmpty && audience.isNotEmpty;
}

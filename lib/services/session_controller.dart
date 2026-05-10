import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/auth0_config.dart';

const _kGuestFlag = 'reliefnet_guest_mode';

enum ReliefNetSession {
  bootstrapping,
  /// Auth0 not configured — legacy open access.
  open,
  /// Must choose login or emergency guest.
  needsLogin,
  authenticated,
  guest,
}

/// Global session: Auth0 credentials + emergency guest flag + cached offline reporter id.
class SessionController extends ChangeNotifier {
  SessionController._();

  static final SessionController instance = SessionController._();

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  ReliefNetSession session = ReliefNetSession.bootstrapping;
  Credentials? _credentials;

  bool get ready => session != ReliefNetSession.bootstrapping;

  bool get isAuthenticated => session == ReliefNetSession.authenticated;

  bool get isGuest => session == ReliefNetSession.guest;

  bool get showLoginGate =>
      ready &&
      Auth0Config.isConfigured &&
      session == ReliefNetSession.needsLogin;

  /// Use on offline SOS payload so hub / sync knows who reported when session existed.
  String? get cachedReporterAuth0Id =>
      _credentials?.user.sub ??
      (isGuest ? 'guest' : null);

  String? get userEmail => _credentials?.user.email;

  String? get userSub => _credentials?.user.sub;

  Future<void> bootstrap() async {
    session = ReliefNetSession.bootstrapping;
    _credentials = null;

    if (!Auth0Config.isConfigured) {
      session = ReliefNetSession.open;
      notifyListeners();
      return;
    }

    final guest = await _secure.read(key: _kGuestFlag);
    if (guest == '1') {
      session = ReliefNetSession.guest;
      notifyListeners();
      return;
    }

    try {
      final auth0 = Auth0(Auth0Config.domain, Auth0Config.clientId);
      final has = await auth0.credentialsManager.hasValidCredentials(minTtl: 60);
      if (has) {
        _credentials = await auth0.credentialsManager.credentials(minTtl: 60);
        session = ReliefNetSession.authenticated;
        notifyListeners();
        return;
      }
    } catch (e, st) {
      debugPrint('Session bootstrap: $e\n$st');
    }

    session = ReliefNetSession.needsLogin;
    notifyListeners();
  }

  Future<void> loginWithUniversalLogin() async {
    if (!Auth0Config.isConfigured) return;

    final auth0 = Auth0(Auth0Config.domain, Auth0Config.clientId);
    final creds = await auth0
        .webAuthentication(scheme: Auth0Config.scheme)
        .login(audience: Auth0Config.audience);

    await _secure.delete(key: _kGuestFlag);
    _credentials = creds;
    session = ReliefNetSession.authenticated;
    notifyListeners();
  }

  Future<void> continueAsEmergencyGuest() async {
    await _secure.write(key: _kGuestFlag, value: '1');
    _credentials = null;
    session = ReliefNetSession.guest;
    notifyListeners();
  }

  /// Leave emergency guest mode and show the login screen (Auth0 remains logged out).
  Future<void> switchFromGuestToLogin() async {
    await _secure.delete(key: _kGuestFlag);
    _credentials = null;
    if (Auth0Config.isConfigured) {
      session = ReliefNetSession.needsLogin;
    } else {
      session = ReliefNetSession.open;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _secure.delete(key: _kGuestFlag);
    _credentials = null;

    if (Auth0Config.isConfigured) {
      try {
        final auth0 = Auth0(Auth0Config.domain, Auth0Config.clientId);
        await auth0.webAuthentication(scheme: Auth0Config.scheme).logout();
      } catch (e, st) {
        debugPrint('Auth0 logout: $e\n$st');
      }
    }

    session =
        Auth0Config.isConfigured ? ReliefNetSession.needsLogin : ReliefNetSession.open;
    notifyListeners();
  }

  /// Bearer token for ReliefNet API (refresh handled by Auth0 credential manager).
  Future<String?> getAccessToken() async {
    if (!Auth0Config.isConfigured || !isAuthenticated) return null;
    try {
      final auth0 = Auth0(Auth0Config.domain, Auth0Config.clientId);
      final c = await auth0.credentialsManager.credentials(minTtl: 120);
      _credentials = c;
      return c.accessToken;
    } catch (e, st) {
      debugPrint('getAccessToken: $e\n$st');
      return null;
    }
  }
}

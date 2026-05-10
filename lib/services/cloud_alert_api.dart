import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/cloud_incident.dart';
import 'session_controller.dart';

class CloudAlertApiException implements Exception {
  CloudAlertApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'CloudAlertApiException($statusCode): $message';
}

class CloudAlertApi {
  CloudAlertApi({
    String? baseUrl,
    Future<String?> Function()? bearerToken,
    SessionController? session,
  })  : baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), ''),
        _bearerToken =
            bearerToken ?? (session ?? SessionController.instance).getAccessToken;

  final String baseUrl;
  final Future<String?> Function() _bearerToken;

  Future<bool> canReachServer() async {
    try {
      final res = await http
          .get(_uri('/health'), headers: await _headers())
          .timeout(const Duration(seconds: 4));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$root$p').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final h = <String, String>{'Accept': 'application/json'};
    if (jsonBody) {
      h['Content-Type'] = 'application/json';
    }
    final token = await _bearerToken();
    if ((token ?? '').trim().isNotEmpty) {
      h['Authorization'] = 'Bearer ${token!.trim()}';
    }
    return h;
  }

  /// [severity] — optional server filter: `Critical`, `High`, `Medium`, or `Low`.
  /// List is sorted by severity priority then newest first.
  Future<List<CloudIncident>> listAlerts({
    String? severity,
    int limit = 200,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (severity != null &&
        (severity == 'Critical' ||
            severity == 'High' ||
            severity == 'Medium' ||
            severity == 'Low')) {
      query['severity'] = severity;
    }

    final res = await http.get(
      _uri('/api/alerts', query),
      headers: await _headers(),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw CloudAlertApiException(
        _extractError(res.body) ?? 'Failed to load incidents (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw CloudAlertApiException('Unexpected list payload.');
    }

    return decoded
        .whereType<Map>()
        .map((e) => CloudIncident.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CloudIncident> getAlert(String id) async {
    final res = await http.get(
      _uri('/api/alerts/${Uri.encodeComponent(id)}'),
      headers: await _headers(),
    );

    if (res.statusCode == 404) {
      throw CloudAlertApiException('Incident not found.', statusCode: 404);
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw CloudAlertApiException(
        _extractError(res.body) ?? 'Failed to load incident (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw CloudAlertApiException('Unexpected incident payload.');
    }

    return CloudIncident.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<CloudIncident> submitAlert({
    required String message,
    String location = '',
    String mode = 'online',
    String source = 'online_cloud',
    String syncStatus = 'synced',
  }) async {
    final normalizedMode = mode.toLowerCase() == 'offline' ? 'offline' : 'online';
    final normalizedSource =
        source == 'offline_hub' || source == 'local_cache' ? source : 'online_cloud';
    final normalizedSync =
        syncStatus == 'pending' || syncStatus == 'failed' ? syncStatus : 'synced';

    final res = await http.post(
      _uri('/api/alerts'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({
        'message': message,
        'location': location,
        'mode': normalizedMode,
        'source': normalizedSource,
        'syncStatus': normalizedSync,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw CloudAlertApiException(
        _extractError(res.body) ?? 'Failed to submit alert (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw CloudAlertApiException('Unexpected alert payload.');
    }

    return CloudIncident.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<CloudIncident> patchResponderStatus({
    required String alertId,
    required String responderStatus,
  }) async {
    final allowed = {'open', 'in_progress', 'closed'};
    if (!allowed.contains(responderStatus)) {
      throw CloudAlertApiException('Invalid responder status.');
    }

    final res = await http.patch(
      _uri('/api/alerts/${Uri.encodeComponent(alertId)}/responder-status'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({'responderStatus': responderStatus}),
    );

    if (res.statusCode == 403) {
      throw CloudAlertApiException(
        _extractError(res.body) ?? 'Responder actions require an admin account.',
        statusCode: 403,
      );
    }

    if (res.statusCode == 404) {
      throw CloudAlertApiException('Incident not found.', statusCode: 404);
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw CloudAlertApiException(
        _extractError(res.body) ??
            'Failed to update responder status (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw CloudAlertApiException('Unexpected incident payload.');
    }

    return CloudIncident.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<List<CloudIncident>> syncAlerts(
    List<Map<String, dynamic>> alerts,
  ) async {
    final res = await http.post(
      _uri('/api/sync-alerts'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({'alerts': alerts}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw CloudAlertApiException(
        _extractError(res.body) ?? 'Failed to sync offline alerts (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw CloudAlertApiException('Unexpected sync payload.');
    }

    return decoded
        .whereType<Map>()
        .map((e) => CloudIncident.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      if (body.trim().isNotEmpty) return body.trim();
    }
    return null;
  }
}

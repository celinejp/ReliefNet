import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/cloud_incident.dart';

class CloudAlertApiException implements Exception {
  CloudAlertApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'CloudAlertApiException($statusCode): $message';
}

class CloudAlertApi {
  CloudAlertApi({String? baseUrl})
      : baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), '');

  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<List<CloudIncident>> listAlerts() async {
    final res = await http.get(
      _uri('/api/alerts'),
      headers: const {'Accept': 'application/json'},
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

  Future<CloudIncident> submitAlert(String message) async {
    final res = await http.post(
      _uri('/api/alerts'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'message': message}),
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

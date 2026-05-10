import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_alert_api.dart';

const _kPendingKey = 'reliefnet_pending_cloud_alerts';

/// Offline queue for POST /api/alerts when the device briefly loses connectivity.
class PendingCloudSync {
  PendingCloudSync._();

  static Future<List<Map<String, dynamic>>> _load(SharedPreferences p) async {
    final raw = p.getString(_kPendingKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(
    SharedPreferences p,
    List<Map<String, dynamic>> items,
  ) async {
    if (items.isEmpty) {
      await p.remove(_kPendingKey);
    } else {
      await p.setString(_kPendingKey, jsonEncode(items));
    }
  }

  static Future<void> enqueue({
    required String message,
    required String location,
    String mode = 'online',
  }) async {
    final p = await SharedPreferences.getInstance();
    final q = await _load(p);
    q.add({
      'message': message,
      'location': location,
      'mode': mode,
      'queuedAt': DateTime.now().toUtc().toIso8601String(),
    });
    await _save(p, q);
    debugPrint('PendingCloudSync: queued (${q.length} pending)');
  }

  static Future<bool> _online() async {
    final r = await Connectivity().checkConnectivity();
    return r.any((e) => e != ConnectivityResult.none);
  }

  /// Sends queued alerts when the network is available.
  static Future<int> flush(CloudAlertApi api) async {
    if (!await _online()) return 0;

    final p = await SharedPreferences.getInstance();
    var q = await _load(p);
    if (q.isEmpty) return 0;

    var sent = 0;
    final remaining = <Map<String, dynamic>>[];

    for (final item in q) {
      final msg = item['message'] as String? ?? '';
      if (msg.trim().isEmpty) continue;
      try {
        await api.submitAlert(
          message: msg.trim(),
          location: (item['location'] as String?)?.trim() ?? '',
          mode: (item['mode'] as String?)?.trim().toLowerCase() == 'offline'
              ? 'offline'
              : 'online',
        );
        sent++;
      } catch (e, st) {
        debugPrint('PendingCloudSync flush failed: $e\n$st');
        remaining.add(item);
      }
    }

    await _save(p, remaining);
    return sent;
  }
}

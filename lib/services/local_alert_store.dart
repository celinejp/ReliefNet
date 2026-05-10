import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/unified_alert.dart';

class LocalAlertStore {
  static const _kUnifiedCache = 'reliefnet_all_alerts_cache';
  static const _kPendingHub = 'reliefnet_pending_hub_alerts';

  Future<List<UnifiedAlert>> readUnifiedCache() async {
    return _readList(_kUnifiedCache);
  }

  Future<void> writeUnifiedCache(List<UnifiedAlert> alerts) async {
    await _writeList(_kUnifiedCache, alerts);
  }

  Future<List<UnifiedAlert>> readPendingHubAlerts() async {
    return _readList(_kPendingHub);
  }

  Future<void> writePendingHubAlerts(List<UnifiedAlert> alerts) async {
    await _writeList(_kPendingHub, alerts);
  }

  Future<List<UnifiedAlert>> _readList(String key) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => UnifiedAlert.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeList(String key, List<UnifiedAlert> alerts) async {
    final p = await SharedPreferences.getInstance();
    if (alerts.isEmpty) {
      await p.remove(key);
      return;
    }
    final body = jsonEncode(alerts.map((e) => e.toJson()).toList());
    await p.setString(key, body);
  }
}

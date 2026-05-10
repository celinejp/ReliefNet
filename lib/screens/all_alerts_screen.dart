import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../models/cloud_incident.dart';
import '../models/unified_alert.dart';
import '../services/cloud_alert_api.dart';
import '../services/local_alert_store.dart';
import '../services/session_controller.dart';
import '../widgets/severity_badge.dart';
import 'alert_detail_screen.dart';

enum _AlertTab { all, critical, medium, low, mine, offlineHub, synced }

class AllAlertsScreen extends StatefulWidget {
  const AllAlertsScreen({super.key});

  @override
  State<AllAlertsScreen> createState() => _AllAlertsScreenState();
}

class _AllAlertsScreenState extends State<AllAlertsScreen> {
  static const String _hubUrl = 'http://192.168.137.1:3001';

  final _api = CloudAlertApi();
  final _store = LocalAlertStore();

  List<UnifiedAlert> _cloudAlerts = const [];
  List<UnifiedAlert> _cachedAlerts = const [];
  List<UnifiedAlert> _pendingHubAlerts = const [];

  socket_io.Socket? _socket;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  List<ConnectivityResult> _connectivity = const [ConnectivityResult.none];
  _AlertTab _tab = _AlertTab.all;
  bool _loading = true;
  String _hubStatus = 'Disconnected';
  String? _lastError;
  bool _disposing = false;

  bool get _online =>
      _connectivity.any((e) => e != ConnectivityResult.none);

  @override
  void initState() {
    super.initState();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((v) async {
      _safeSetState(() => _connectivity = v);
      await _refreshAll();
    });
    Connectivity().checkConnectivity().then((v) async {
      _safeSetState(() => _connectivity = v);
      await _refreshAll();
    });
    _connectToHub();
  }

  @override
  void dispose() {
    _disposing = true;
    _connectivitySub?.cancel();
    _socket?.dispose();
    super.dispose();
  }

  bool get _canUpdateUi => mounted && !_disposing;

  void _safeSetState(VoidCallback fn) {
    if (!_canUpdateUi) return;
    setState(fn);
  }

  void _connectToHub() {
    _socket?.dispose();
    _socket = socket_io.io(
      _hubUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setReconnectionAttempts(4)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket?.onConnect((_) {
      if (!_canUpdateUi) return;
      _safeSetState(() => _hubStatus = 'Connected');
      _socket?.emit('subscribe', {'client': 'reliefnet-all-alerts'});
    });
    _socket?.onDisconnect((_) {
      if (!_canUpdateUi) return;
      _safeSetState(() => _hubStatus = 'Disconnected');
    });
    _socket?.onConnectError((_) {
      if (!_canUpdateUi) return;
      _safeSetState(() => _hubStatus = 'Connect error');
    });
    _socket?.on('alerts', (data) async {
      if (!_canUpdateUi) return;
      if (data is! List) return;
      final incoming = data
          .whereType<Map>()
          .map((e) => _fromHubPayload(Map<String, dynamic>.from(e)))
          .toList();
      _pendingHubAlerts = _dedupe([..._pendingHubAlerts, ...incoming]);
      await _store.writePendingHubAlerts(_pendingHubAlerts);
      if (!_canUpdateUi) return;
      _safeSetState(() {});
    });
    _socket?.on('alert-received', (data) async {
      if (!_canUpdateUi) return;
      if (data is! Map) return;
      final alert = _fromHubPayload(Map<String, dynamic>.from(data));
      _pendingHubAlerts = _dedupe([alert, ..._pendingHubAlerts]);
      await _store.writePendingHubAlerts(_pendingHubAlerts);
      if (!_canUpdateUi) return;
      _safeSetState(() {});
    });

    _socket?.connect();
  }

  UnifiedAlert _fromHubPayload(Map<String, dynamic> payload) {
    final created =
        DateTime.tryParse('${payload['timestamp'] ?? payload['createdAt'] ?? ''}') ??
            DateTime.now();
    final message = (payload['message'] as String? ?? '').trim();
    final location = (payload['location'] as String? ?? '').trim();
    final userEmail = (payload['userEmail'] as String? ?? '').trim();
    final userId = (payload['auth0UserId'] as String? ?? '').trim();
    final severity = (payload['severity'] as String? ?? '').trim();

    final rawHubId = (payload['id'] as String? ?? '').trim();
    return UnifiedAlert(
      id: rawHubId.isNotEmpty
          ? 'hub_$rawHubId'
          : 'hub_${created.microsecondsSinceEpoch}_${message.hashCode}',
      userId: userId.isEmpty ? null : userId,
      userEmail: userEmail.isEmpty ? null : userEmail,
      message: message.isEmpty ? 'Offline hub alert' : message,
      location: location.isEmpty ? null : location,
      severity: severity.isEmpty ? null : severity,
      createdAt: created,
      source: 'offline_hub',
      syncStatus: 'pending',
      mode: 'offline',
      isMine: _isMine(userId, userEmail),
    );
  }

  bool _isMine(String? userId, String? userEmail) {
    final s = SessionController.instance;
    final myId = (s.userSub ?? '').trim();
    final myEmail = (s.userEmail ?? '').trim().toLowerCase();
    final candidateId = (userId ?? '').trim();
    final candidateEmail = (userEmail ?? '').trim().toLowerCase();
    if (candidateId.isNotEmpty && myId.isNotEmpty && candidateId == myId) {
      return true;
    }
    return candidateEmail.isNotEmpty &&
        myEmail.isNotEmpty &&
        candidateEmail == myEmail;
  }

  Future<void> _refreshAll() async {
    if (!_canUpdateUi) return;
    _safeSetState(() {
      _loading = true;
      _lastError = null;
    });

    _cachedAlerts = await _store.readUnifiedCache();
    _pendingHubAlerts = await _store.readPendingHubAlerts();

    if (_online && _pendingHubAlerts.isNotEmpty) {
      try {
        await _api.syncAlerts(
          _pendingHubAlerts
              .map(
                (e) => {
                  'clientAlertId': e.id,
                  'message': e.message,
                  'location': e.location ?? '',
                  'userId': e.userId ?? '',
                  'userEmail': e.userEmail ?? '',
                  'createdAt': e.createdAt.toIso8601String(),
                  'source': 'offline_hub',
                  'mode': 'offline',
                },
              )
              .toList(),
        );
        _pendingHubAlerts = const [];
        await _store.writePendingHubAlerts(const []);
      } catch (e) {
        _lastError = '$e';
      }
    }

    if (_online) {
      try {
        final cloud = await _api.listAlerts(limit: 300);
        _cloudAlerts = cloud.map(_fromCloud).toList();
        final localCache = _cloudAlerts
            .map(
              (e) => UnifiedAlert(
                id: e.id,
                userId: e.userId,
                userEmail: e.userEmail,
                message: e.message,
                location: e.location,
                severity: e.severity,
                createdAt: e.createdAt,
                source: 'local_cache',
                syncStatus: e.syncStatus,
                mode: e.mode,
                isMine: e.isMine,
              ),
            )
            .toList();
        _cachedAlerts = localCache;
        await _store.writeUnifiedCache(localCache);
      } catch (e) {
        _lastError = '$e';
      }
    } else {
      _cloudAlerts = const [];
    }

    if (!_canUpdateUi) return;
    _safeSetState(() => _loading = false);
  }

  UnifiedAlert _fromCloud(CloudIncident c) {
    final msg = c.rawMessage.trim().isNotEmpty ? c.rawMessage : c.summary;
    final created = c.createdAt ?? DateTime.now();
    return UnifiedAlert(
      id: c.id,
      userId: c.auth0UserId,
      userEmail: c.userEmail,
      message: msg,
      location: c.location,
      severity: c.severity,
      createdAt: created,
      source: c.source ?? 'online_cloud',
      syncStatus: c.syncStatus ?? 'synced',
      mode: c.mode,
      isMine: _isMine(c.auth0UserId, c.userEmail),
    );
  }

  List<UnifiedAlert> get _merged {
    final map = <String, UnifiedAlert>{};
    for (final a in _cachedAlerts) {
      _upsertByFingerprint(map, a);
    }
    for (final a in _pendingHubAlerts) {
      _upsertByFingerprint(map, a);
    }
    for (final a in _cloudAlerts) {
      _upsertByFingerprint(map, a);
    }
    final list = map.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<UnifiedAlert> _dedupe(List<UnifiedAlert> items) {
    final map = <String, UnifiedAlert>{};
    for (final i in items) {
      _upsertByFingerprint(map, i);
    }
    final values = map.values.toList();
    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  void _upsertByFingerprint(Map<String, UnifiedAlert> map, UnifiedAlert alert) {
    final key = _mergeKey(alert);
    final existing = map[key];
    if (existing == null || _priority(alert) > _priority(existing)) {
      map[key] = alert;
    }
  }

  String _mergeKey(UnifiedAlert a) {
    final id = a.id.trim();
    if (a.source == 'offline_hub' && a.syncStatus == 'synced') {
      // Collapse old duplicated cloud records from prior non-idempotent sync runs.
      return 'offline:${_fingerprint(a)}';
    }
    if (id.isNotEmpty && !id.startsWith('hub_')) {
      return 'id:$id';
    }
    return 'fp:${_fingerprint(a)}';
  }

  int _priority(UnifiedAlert a) {
    final sourceWeight = switch (a.source) {
      'online_cloud' => 300,
      'offline_hub' => 200,
      'local_cache' => 100,
      _ => 0,
    };
    final syncWeight = switch (a.syncStatus) {
      'synced' => 30,
      'pending' => 20,
      'failed' => 10,
      _ => 0,
    };
    return sourceWeight + syncWeight;
  }

  String _fingerprint(UnifiedAlert a) {
    final msg = a.message.trim().toLowerCase();
    final loc = (a.location ?? '').trim().toLowerCase();
    final email = (a.userEmail ?? '').trim().toLowerCase();
    final id = (a.userId ?? '').trim().toLowerCase();
    return '$msg|$loc|$email|$id';
  }

  List<UnifiedAlert> get _visible {
    final items = _merged;
    return switch (_tab) {
      _AlertTab.all => items,
      _AlertTab.critical => items.where((a) => a.severity == 'Critical').toList(),
      _AlertTab.medium => items.where((a) => a.severity == 'Medium').toList(),
      _AlertTab.low => items.where((a) => a.severity == 'Low').toList(),
      _AlertTab.mine => items.where((a) => a.isMine).toList(),
      _AlertTab.offlineHub =>
        items.where((a) => a.source == 'offline_hub').toList(),
      _AlertTab.synced => items.where((a) => a.syncStatus == 'synced').toList(),
    };
  }

  String _sourceLabel(UnifiedAlert a) {
    if (a.source == 'offline_hub' && a.syncStatus == 'synced') {
      return 'MongoDB + Offline Hub';
    }
    return switch (a.source) {
      'online_cloud' => 'Online Cloud',
      'offline_hub' => 'Offline Hub',
      'local_cache' => 'Local Cache',
      _ => 'Unknown',
    };
  }

  String _timeLabel(DateTime t) {
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Alerts'),
        actions: [
          IconButton(
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tabChip('All', _AlertTab.all),
                _tabChip('Critical', _AlertTab.critical),
                _tabChip('Medium', _AlertTab.medium),
                _tabChip('Low', _AlertTab.low),
                _tabChip('My Alerts', _AlertTab.mine),
                _tabChip('Offline Hub', _AlertTab.offlineHub),
                _tabChip('Synced', _AlertTab.synced),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Icon(
                  _online ? Icons.cloud_done_rounded : Icons.wifi_off_rounded,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _online
                        ? 'Online mode: cloud feed + synced offline alerts.'
                        : 'Offline mode: local hub + cached alerts only.',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Text(
                  'Hub: $_hubStatus',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          if (_lastError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                _lastError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshAll,
                    child: items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            children: const [
                              Text('No alerts in this filter.'),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                            itemCount: items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final a = items[i];
                              return Material(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _online && a.source != 'local_cache'
                                      ? () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  AlertDetailScreen(alertId: a.id),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            SeverityBadge(severity: a.severity),
                                            const Spacer(),
                                            Text(
                                              _timeLabel(a.createdAt),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: Colors.white70,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          a.message,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                        if ((a.location ?? '').trim().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Location: ${a.location}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(color: Colors.white70),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                          'Source: ${_sourceLabel(a)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.white70),
                                        ),
                                        Text(
                                          'Status: ${a.syncStatus == 'pending' ? 'Pending Sync' : a.syncStatus == 'failed' ? 'Sync Failed' : 'Synced'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.white70),
                                        ),
                                        Text(
                                          'Submitted by: ${(a.userEmail ?? '').trim().isEmpty ? 'Unknown' : a.userEmail}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, _AlertTab tab) {
    return FilterChip(
      label: Text(label),
      selected: _tab == tab,
      onSelected: (_) => setState(() => _tab = tab),
    );
  }
}

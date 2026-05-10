import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../models/unified_alert.dart';
import '../services/local_alert_store.dart';
import '../services/session_controller.dart';

class OfflineAlertScreen extends StatefulWidget {
  const OfflineAlertScreen({super.key});

  @override
  State<OfflineAlertScreen> createState() => _OfflineAlertScreenState();
}

class _OfflineAlertScreenState extends State<OfflineAlertScreen> {
  static const String _serverUrl = 'http://192.168.137.1:3001';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final LocalAlertStore _localStore = LocalAlertStore();
  final List<Map<String, dynamic>> _alerts = [];
  socket_io.Socket? _socket;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  String _status = 'Disconnected';
  String _connectionType = 'unknown';
  bool _disposing = false;

  bool get _canUpdateUi => mounted && !_disposing;

  void _safeSetState(VoidCallback fn) {
    if (!_canUpdateUi) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sess = SessionController.instance;
      if (!mounted) return;
      if (sess.isAuthenticated && _nameController.text.trim().isEmpty) {
        final hint =
            (sess.userEmail ?? sess.userSub ?? '').trim();
        if (hint.isNotEmpty) _nameController.text = hint;
      }
    });
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((statuses) {
      if (!_canUpdateUi) return;
      final first =
          statuses.isEmpty ? ConnectivityResult.none : statuses.first;
      _safeSetState(() {
        _connectionType = first.toString().split('.').last;
      });
    });
    _connect();
  }

  @override
  void dispose() {
    _disposing = true;
    _connectivitySub?.cancel();
    _socket?.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _connect() {
    if (_socket?.connected == true) return;

    _socket?.dispose();
    _socket = socket_io.io(
      _serverUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket?.onConnect((_) {
      if (!_canUpdateUi) return;
      _safeSetState(() {
        _status = 'Connected';
      });
      _socket?.emit('subscribe', {'client': 'reliefnet-app'});
    });

    _socket?.onDisconnect((_) {
      if (!_canUpdateUi) return;
      _safeSetState(() {
        _status = 'Disconnected';
      });
    });

    _socket?.onConnectError((data) {
      if (!_canUpdateUi) return;
      _safeSetState(() {
        _status = 'Connect error';
      });
      _showSnackbar('Connection failed. Check laptop IP and hotspot network.');
    });

    _socket?.on('alerts', (data) {
      if (!_canUpdateUi) return;
      if (data is List) {
        _safeSetState(() {
          _alerts.clear();
          _alerts.addAll(data.cast<Map<String, dynamic>>());
        });
      }
    });

    _socket?.on('alert-received', (data) {
      if (!_canUpdateUi) return;
      if (data is Map) {
        _safeSetState(() {
          _alerts.insert(0, Map<String, dynamic>.from(data));
        });
      }
    });

    _socket?.connect();
    if (!_canUpdateUi) return;
    _safeSetState(() {
      _status = 'Connecting';
    });
  }

  Future<void> _sendAlert() async {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final message = _messageController.text.trim();

    if (name.isEmpty || location.isEmpty || message.isEmpty) {
      _showSnackbar('Fill name, location and message to send an alert.');
      return;
    }

    if (_socket == null || _socket?.connected != true) {
      _showSnackbar('Connecting to hub...');
      _connect();
      Future.delayed(const Duration(milliseconds: 500), () {
        _sendAlert();
      });
      return;
    }

    final sess = SessionController.instance;
    final alert = {
      'reporter': name,
      'location': location,
      'message': message,
      'type': 'SOS',
      'timestamp': DateTime.now().toIso8601String(),
      'auth0UserId': sess.cachedReporterAuth0Id,
      'userEmail': sess.userEmail,
      'guestMode': sess.isGuest,
      'mode': 'offline',
    };

    final now = DateTime.now();
    final stableId = 'hub_${now.millisecondsSinceEpoch}_${message.hashCode}';
    alert['id'] = stableId;
    _socket?.emit('new-alert', alert);
    final pending = await _localStore.readPendingHubAlerts();
    pending.insert(
      0,
      UnifiedAlert(
        id: stableId,
        userId: sess.cachedReporterAuth0Id,
        userEmail: sess.userEmail,
        message: message,
        location: location,
        severity: null,
        createdAt: now,
        source: 'offline_hub',
        syncStatus: 'pending',
        mode: 'offline',
        clientAlertId: stableId,
        isMine: true,
      ),
    );
    await _localStore.writePendingHubAlerts(pending);
    _showSnackbar('Alert sent to laptop hub.');
    _nameController.clear();
    _locationController.clear();
    _messageController.clear();
  }

  void _showSnackbar(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _statusChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReliefNet Offline Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _connect,
            tooltip: 'Reconnect',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Offline communication mode',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your emergency report will automatically connect to the offline hub and be recorded.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              _statusChip('Hub status', _status),
              const SizedBox(height: 10),
              _statusChip('Network', _connectionType),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Your name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location / landmark'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Emergency message'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _sendAlert,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Send SOS alert'),
              ),
              const SizedBox(height: 24),
              Text(
                'Live alerts from hub',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (_alerts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text('No alerts received yet.'),
                )
              else
                Column(
                  children: _alerts.map((alert) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alert['reporter'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(alert['message'] ?? '', style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(alert['location'] ?? '', style: const TextStyle(color: Colors.white60)),
                                Text(alert['timestamp']?.toString().split('T').first ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

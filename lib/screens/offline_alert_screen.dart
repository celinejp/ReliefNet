import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../config/hub_config.dart';
import '../models/unified_alert.dart';
import '../services/local_alert_store.dart';
import '../services/session_controller.dart';

class OfflineAlertScreen extends StatefulWidget {
  const OfflineAlertScreen({super.key});

  @override
  State<OfflineAlertScreen> createState() => _OfflineAlertScreenState();
}

class _OfflineAlertScreenState extends State<OfflineAlertScreen> {
  static const String _serverUrl = HubConfig.baseUrl;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final LocalAlertStore _localStore = LocalAlertStore();
  final List<Map<String, dynamic>> _alerts = [];
  socket_io.Socket? _socket;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  _PendingOfflineAlert? _pendingAlert;
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
        final hint = (sess.userEmail ?? sess.userSub ?? '').trim();
        if (hint.isNotEmpty) _nameController.text = hint;
      }
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((statuses) {
      if (!_canUpdateUi) return;
      final first = statuses.isEmpty ? ConnectivityResult.none : statuses.first;
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
    _disposeSocket();
    _nameController.dispose();
    _locationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _disposeSocket() {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;

    socket.clearListeners();
    socket.dispose();
  }

  void _connect() {
    if (!_canUpdateUi) return;
    if (_socket?.connected == true) return;

    _disposeSocket();

    _socket = socket_io.io(
      _serverUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .disableMultiplex()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .setTimeout(5000)
          .build(),
    );

    _socket?.onConnect((_) {
      if (!_canUpdateUi) return;
      _safeSetState(() {
        _status = 'Connected';
      });
      _socket?.emit('subscribe', {'client': 'reliefnet-app'});
      _sendPendingAlert();
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
          _alerts.addAll(
            data
                .whereType<Map>()
                .map((alert) => Map<String, dynamic>.from(alert)),
          );
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

    _safeSetState(() {
      _status = 'Connecting';
    });
    _socket?.connect();
  }

  Future<void> _sendAlert() async {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final message = _messageController.text.trim();

    if (name.isEmpty || location.isEmpty || message.isEmpty) {
      _showSnackbar('Fill name, location and message to send an alert.');
      return;
    }

    final sess = SessionController.instance;
    final now = DateTime.now();
    final stableId = 'hub_${now.millisecondsSinceEpoch}_${message.hashCode}';
    final alert = {
      'id': stableId,
      'reporter': name,
      'location': location,
      'message': message,
      'type': 'SOS',
      'timestamp': now.toIso8601String(),
      'auth0UserId': sess.cachedReporterAuth0Id,
      'userEmail': sess.userEmail,
      'guestMode': sess.isGuest,
      'mode': 'offline',
    };

    final pending = _PendingOfflineAlert(
      alert: alert,
      stableId: stableId,
      userId: sess.cachedReporterAuth0Id,
      userEmail: sess.userEmail,
      message: message,
      location: location,
      createdAt: now,
    );

    if (_socket == null || _socket?.connected != true) {
      _pendingAlert = pending;
      _showSnackbar('Connecting to hub...');
      _connect();
      return;
    }

    await _emitAlert(pending);
  }

  Future<void> _sendPendingAlert() async {
    final pending = _pendingAlert;
    if (pending == null || _socket?.connected != true) return;

    _pendingAlert = null;
    await _emitAlert(pending);
  }

  Future<void> _emitAlert(_PendingOfflineAlert pending) async {
    _socket?.emit('new-alert', pending.alert);
    final saved = await _localStore.readPendingHubAlerts();
    saved.insert(
      0,
      UnifiedAlert(
        id: pending.stableId,
        userId: pending.userId,
        userEmail: pending.userEmail,
        message: pending.message,
        location: pending.location,
        severity: null,
        createdAt: pending.createdAt,
        source: 'offline_hub',
        syncStatus: 'pending',
        mode: 'offline',
        clientAlertId: pending.stableId,
        isMine: true,
      ),
    );
    await _localStore.writePendingHubAlerts(saved);
    _showSnackbar('Alert sent to laptop hub.');
    _nameController.clear();
    _locationController.clear();
    _messageController.clear();
  }

  void _showSnackbar(String text) {
    if (!_canUpdateUi) return;
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
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AlertU Offline Hub'),
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
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your emergency report will automatically connect to the offline hub and be recorded.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Location / landmark',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Emergency message',
                ),
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
                            Text(
                              alert['reporter'] ?? 'Unknown',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              alert['message'] ?? '',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  alert['location'] ?? '',
                                  style: const TextStyle(color: Colors.white60),
                                ),
                                Text(
                                  alert['timestamp']
                                          ?.toString()
                                          .split('T')
                                          .first ??
                                      '',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
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

class _PendingOfflineAlert {
  const _PendingOfflineAlert({
    required this.alert,
    required this.stableId,
    required this.userId,
    required this.userEmail,
    required this.message,
    required this.location,
    required this.createdAt,
  });

  final Map<String, dynamic> alert;
  final String stableId;
  final String? userId;
  final String? userEmail;
  final String message;
  final String location;
  final DateTime createdAt;
}

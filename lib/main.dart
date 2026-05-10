import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ReliefNetApp());
}

class ReliefNetApp extends StatelessWidget {
  const ReliefNetApp({super.key});

  static const _brandTeal = Color(0xFF0F766E);
  static const _brandDeep = Color(0xFF0B1220);
  static const _accent = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    final baseDark = ColorScheme.fromSeed(
      seedColor: _brandTeal,
      brightness: Brightness.dark,
    );

    final colorScheme = baseDark.copyWith(
      primary: _brandTeal,
      secondary: _accent,
      surface: const Color(0xFF111827),
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _brandDeep,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface.withValues(alpha: 0.92),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    return MaterialApp(
      title: 'ReliefNet',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _stubAction(BuildContext context, String label) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — wiring comes next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            backgroundColor: ReliefNetApp._brandDeep,
            title: const Text('ReliefNet'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.35),
                        colorScheme.secondary.withValues(alpha: 0.22),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stay connected when networks fail.',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Hybrid offline LAN alerts and online AI triage — '
                        'built for HackDavis 2026.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _StatusChip(
                            icon: Icons.wifi_tethering_rounded,
                            label: 'Offline hub',
                            stateLabel: 'Not linked',
                          ),
                          _StatusChip(
                            icon: Icons.cloud_outlined,
                            label: 'Cloud',
                            stateLabel: 'Not signed in',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Quick actions',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.emergency_rounded,
                  iconBackground: colorScheme.error.withValues(alpha: 0.18),
                  iconColor: colorScheme.error,
                  title: 'Submit SOS alert',
                  subtitle: 'Offline LAN or cloud — routing arrives later.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OfflineAlertScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.person_search_rounded,
                  iconBackground: colorScheme.primary.withValues(alpha: 0.18),
                  iconColor: colorScheme.primary,
                  title: 'Report missing person',
                  subtitle: 'Structured details for duplicate matching.',
                  onTap: () => _stubAction(context, 'Missing person report'),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.dashboard_customize_rounded,
                  iconBackground: colorScheme.secondary.withValues(alpha: 0.18),
                  iconColor: colorScheme.secondary,
                  title: 'Incident dashboard',
                  subtitle: 'Responder view will stream live updates.',
                  onTap: () => _stubAction(context, 'Incident dashboard'),
                ),
                const SizedBox(height: 28),
                Text(
                  'How ReliefNet fits your drill',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _Bullet(
                  icon: Icons.router_rounded,
                  text:
                      'Phones join the same hotspot; the laptop hub carries alerts when cellular drops.',
                ),
                _Bullet(
                  icon: Icons.psychology_alt_outlined,
                  text:
                      'When online, Gemini classifies severity and cleans noisy reports.',
                ),
                _Bullet(
                  icon: Icons.merge_rounded,
                  text:
                      'AI grouping surfaces duplicate missing-person sightings.',
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class OfflineAlertScreen extends StatefulWidget {
  const OfflineAlertScreen({super.key});

  @override
  State<OfflineAlertScreen> createState() => _OfflineAlertScreenState();
}

class _OfflineAlertScreenState extends State<OfflineAlertScreen> {
  final TextEditingController _serverController = TextEditingController(text: 'http://192.168.1.100:3001');
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _alerts = [];
  IO.Socket? _socket;
  String _status = 'Disconnected';
  String _connectionType = 'unknown';

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((status) {
      setState(() {
        _connectionType = status.toString().split('.').last;
      });
    });
  }

  @override
  void dispose() {
    _socket?.dispose();
    _serverController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _connect() {
    final serverUrl = _serverController.text.trim();
    if (serverUrl.isEmpty) {
      _showSnackbar('Enter the laptop hub address first.');
      return;
    }

    _socket?.dispose();
    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket?.onConnect((_) {
      setState(() {
        _status = 'Connected';
      });
      _socket?.emit('subscribe', {'client': 'reliefnet-app'});
    });

    _socket?.onDisconnect((_) {
      setState(() {
        _status = 'Disconnected';
      });
    });

    _socket?.onConnectError((data) {
      setState(() {
        _status = 'Connect error';
      });
      _showSnackbar('Connection failed. Check laptop IP and hotspot network.');
    });

    _socket?.on('alerts', (data) {
      if (data is List) {
        setState(() {
          _alerts.clear();
          _alerts.addAll(data.cast<Map<String, dynamic>>());
        });
      }
    });

    _socket?.on('alert-received', (data) {
      if (data is Map) {
        setState(() {
          _alerts.insert(0, Map<String, dynamic>.from(data as Map));
        });
      }
    });

    _socket?.connect();
    setState(() {
      _status = 'Connecting';
    });
  }

  void _disconnect() {
    _socket?.disconnect();
    setState(() {
      _status = 'Disconnected';
    });
  }

  void _sendAlert() {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final message = _messageController.text.trim();

    if (name.isEmpty || location.isEmpty || message.isEmpty) {
      _showSnackbar('Fill name, location and message to send an alert.');
      return;
    }

    final alert = {
      'reporter': name,
      'location': location,
      'message': message,
      'type': 'SOS',
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (_socket == null || _socket?.connected != true) {
      _showSnackbar('Not connected to offline hub. Tap Connect first.');
      return;
    }

    _socket?.emit('new-alert', alert);
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
        color: Colors.white.withOpacity(0.08),
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
                'Connect to the laptop hub using the local IP address from your laptop. Then submit an SOS alert so the responder dashboard can show the report in real time.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              _statusChip('Socket.IO status', _status),
              const SizedBox(height: 10),
              _statusChip('Network type', _connectionType),
              const SizedBox(height: 18),
              TextField(
                controller: _serverController,
                decoration: const InputDecoration(
                  labelText: 'Laptop hub address',
                  hintText: 'http://192.168.x.x:3001',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _connect,
                      child: const Text('Connect'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _disconnect,
                      child: const Text('Disconnect'),
                    ),
                  ),
                ],
              ),
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
                    color: Colors.white.withOpacity(0.04),
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

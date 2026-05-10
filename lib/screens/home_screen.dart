import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../config/build_info.dart';
import '../relief_net_app.dart';
import 'incident_dashboard_screen.dart';
import 'submit_online_alert_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  List<ConnectivityResult> _connectivity = const [ConnectivityResult.none];

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then((v) {
      if (mounted) setState(() => _connectivity = v);
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((v) {
      if (mounted) setState(() => _connectivity = v);
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  bool get _hasNetwork =>
      _connectivity.any((r) => r != ConnectivityResult.none);

  void _stub(BuildContext context, String label) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final cloudDetail =
        _hasNetwork ? 'Online mode ready' : 'No network link';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            backgroundColor: ReliefNetApp.brandDeep,
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
                        'Hybrid offline LAN alerts and online Claude triage — '
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
                        children: [
                          const _StatusChip(
                            icon: Icons.wifi_tethering_rounded,
                            label: 'Offline hub',
                            stateLabel: 'Not linked',
                          ),
                          _StatusChip(
                            icon: Icons.cloud_outlined,
                            label: 'Cloud',
                            stateLabel: cloudDetail,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'API ${ApiConfig.baseUrl}',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 6),
                  Text(
                    kBuildLabel.isEmpty
                        ? 'DEBUG build — pass --dart-define=BUILD_LABEL=main@abc1234'
                        : 'DEBUG build — $kBuildLabel',
                    style: textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFFBBF24),
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
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
                  title: 'Submit SOS alert (online)',
                  subtitle:
                      'Send to MongoDB + Claude when you have internet or LAN '
                      'reachability to the API.',
                  enabled: _hasNetwork,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SubmitOnlineAlertScreen(),
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
                  enabled: true,
                  onTap: () => _stub(context, 'Missing person report'),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.dashboard_customize_rounded,
                  iconBackground: colorScheme.secondary.withValues(alpha: 0.18),
                  iconColor: colorScheme.secondary,
                  title: 'Incident dashboard',
                  subtitle: 'Prioritized incidents from the cloud feed.',
                  enabled: _hasNetwork,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const IncidentDashboardScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  'How ReliefNet fits your drill',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const _Bullet(
                  icon: Icons.router_rounded,
                  text:
                      'Phones join the same hotspot; the laptop hub carries alerts when cellular drops.',
                ),
                const _Bullet(
                  icon: Icons.psychology_alt_outlined,
                  text:
                      'When online, Claude classifies severity and cleans noisy reports.',
                ),
                const _Bullet(
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.stateLabel,
  });

  final IconData icon;
  final String label;
  final String stateLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ReliefNetApp.brandDeep.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.secondary),
          const SizedBox(width: 8),
          Text(
            '$label · ',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            stateLabel.isEmpty ? '—' : stateLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled
            ? onTap
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Connect to Wi‑Fi or cellular first.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? null
                            : Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(
                          alpha: enabled ? 0.72 : 0.35,
                        ),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: enabled ? 0.35 : 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

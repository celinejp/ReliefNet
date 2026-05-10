import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../config/build_info.dart';
import '../features/person_report/screens/person_report_form_screen.dart';
import '../features/person_report/screens/reports_display_screen.dart';
import '../features/volunteer/screens/donation_form_screen.dart';
import '../features/volunteer/screens/volunteer_dashboard_screen.dart';
import '../features/volunteer/screens/volunteer_form_screen.dart';
import '../relief_net_app.dart';
import 'incident_dashboard_screen.dart';
import 'offline_alert_screen.dart';
import 'submit_online_alert_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ReliefNet',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Emergency coordination for offline-first response teams.',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Getting started',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _Bullet(
                      icon: Icons.wifi_tethering_rounded,
                      text: 'Connect phones to the same local hotspot or LAN.',
                    ),
                    const _Bullet(
                      icon: Icons.signal_cellular_alt_rounded,
                      text: 'Use offline hub mode when internet is unavailable.',
                    ),
                    const _Bullet(
                      icon: Icons.flash_on_rounded,
                      text: 'Tap Get started to access quick response actions.',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const QuickActionsScreen(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Get started'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const QuickActionsScreen(),
                    ),
                  );
                },
                child: const Text('Explore quick actions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickActionsScreen extends StatefulWidget {
  const QuickActionsScreen({super.key});

  @override
  State<QuickActionsScreen> createState() => _QuickActionsScreenState();
}

class _QuickActionsScreenState extends State<QuickActionsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final cloudDetail = _hasNetwork ? 'Online mode ready' : 'No network link';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick actions'),
        backgroundColor: ReliefNetApp.brandDeep,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                        'Ready to respond',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Choose an action to submit alerts, report missing people, or view the incident dashboard.',
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
                            stateLabel: 'Tap offline action',
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
                      'Send to MongoDB + Claude when you have internet or LAN reachability to the API.',
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
                  icon: Icons.wifi_off_rounded,
                  iconBackground: colorScheme.error.withValues(alpha: 0.18),
                  iconColor: colorScheme.error,
                  title: 'Submit SOS alert offline',
                  subtitle: 'LAN-only — connects to laptop hub over hotspot.',
                  enabled: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
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
                  enabled: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PersonReportFormScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.groups_rounded,
                  iconBackground: colorScheme.tertiary.withValues(alpha: 0.18),
                  iconColor: colorScheme.tertiary,
                  title: 'View person reports',
                  subtitle:
                      'Browse matches and unmatched reports with AI grouping.',
                  enabled: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ReportsDisplayScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.people_alt_rounded,
                  iconBackground: colorScheme.primary.withValues(alpha: 0.18),
                  iconColor: colorScheme.primary,
                  title: 'Volunteer Matching',
                  subtitle: 'Register volunteers and AI-match them.',
                  enabled: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const VolunteerDashboardScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.assignment_rounded,
                  iconBackground: colorScheme.tertiary.withValues(alpha: 0.18),
                  iconColor: colorScheme.tertiary,
                  title: 'Request / Offer Help',
                  subtitle:
                      'Submit needs or offer resources and assistance.',
                  enabled: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const VolunteerFormScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.volunteer_activism_rounded,
                  iconBackground: colorScheme.secondary.withValues(alpha: 0.18),
                  iconColor: colorScheme.secondary,
                  title: 'Donate Supplies',
                  subtitle: 'Submit medicine, food, clothing donations.',
                  enabled: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DonationFormScreen(),
                      ),
                    );
                  },
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

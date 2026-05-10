import '../features/volunteer/screens/volunteer_form_screen.dart';
import '../features/volunteer/screens/volunteer_dashboard_screen.dart';
import '../features/volunteer/screens/donation_form_screen.dart';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../config/build_info.dart';
import '../features/person_report/screens/person_report_form_screen.dart';
import '../features/person_report/screens/reports_display_screen.dart';
import '../relief_net_app.dart';
import 'offline_alert_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final cloudDetail = _hasNetwork
        ? 'Online mode ready'
        : 'No network link';

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
                        'Hybrid offline LAN alerts and online Claude triage — built for HackDavis 2026.',

                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.45,
                        ),
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
                  iconBackground:
                      colorScheme.error.withValues(alpha: 0.18),
                  iconColor: colorScheme.error,
                  title: 'Submit SOS alert (online)',

                  subtitle:
                      'Send to MongoDB + Claude when online.',

                  enabled: _hasNetwork,

                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const SubmitOnlineAlertScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _ActionTile(
                  icon: Icons.wifi_off_rounded,
                  iconBackground:
                      colorScheme.error.withValues(alpha: 0.18),
                  iconColor: colorScheme.error,
                  title: 'Submit SOS alert offline',

                  subtitle:
                      'LAN-only hotspot emergency reporting.',

                  enabled: true,

                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const OfflineAlertScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _ActionTile(
                  icon: Icons.person_search_rounded,
                  iconBackground:
                      colorScheme.primary.withValues(alpha: 0.18),
                  iconColor: colorScheme.primary,
                  title: 'Report missing person',

                  subtitle:
                      'Structured details for duplicate matching.',

                  enabled: true,

                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const PersonReportFormScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _ActionTile(
                  icon: Icons.groups_rounded,
                  iconBackground:
                      colorScheme.tertiary.withValues(alpha: 0.18),
                  iconColor: colorScheme.tertiary,
                  title: 'View person reports',

                  subtitle:
                      'Browse AI-grouped reports and matches.',

                  enabled: true,

                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const ReportsDisplayScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _ActionTile(
                  icon: Icons.people_alt_rounded,
                  iconBackground:
                      colorScheme.primary.withValues(alpha: 0.18),
                  iconColor: colorScheme.primary,
                  title: 'Volunteer Matching',

                  subtitle:
                      'Register volunteers and AI-match them.',

                  enabled: true,

                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const VolunteerDashboardScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _ActionTile(
                  icon: Icons.assignment_rounded,
                  iconBackground:
                      colorScheme.tertiary.withValues(alpha: 0.18),
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
                  iconBackground:
                      colorScheme.secondary.withValues(alpha: 0.18),
                  iconColor: colorScheme.secondary,
                  title: 'Donate Supplies',

                  subtitle:
                      'Submit medicine, food, clothing donations.',

                  enabled: true,

                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const DonationFormScreen(),
                      ),
                    );
                  },
                ),


              ]),
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
      color:
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),

      borderRadius: BorderRadius.circular(16),

      child: InkWell(
        borderRadius: BorderRadius.circular(16),

        onTap: onTap,

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

                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
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
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      subtitle,

                      style: textTheme.bodySmall?.copyWith(
                        color:
                            Colors.white.withValues(alpha: 0.72),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
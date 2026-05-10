import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../config/auth0_config.dart';
import '../features/person_report/screens/person_report_form_screen.dart';
import '../features/person_report/screens/reports_display_screen.dart';
import '../features/volunteer/screens/volunteer_dashboard_screen.dart';
import '../features/volunteer/screens/volunteer_form_screen.dart';
import '../relief_net_app.dart';
import '../services/cloud_alert_api.dart';
import '../services/pending_cloud_sync.dart';
import '../services/session_controller.dart';
import 'all_alerts_screen.dart';
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
    Connectivity().checkConnectivity().then((v) async {
      if (!mounted) return;
      setState(() => _connectivity = v);
      await _flushQueuedAlerts(v);
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((v) async {
      if (!mounted) return;
      setState(() => _connectivity = v);
      await _flushQueuedAlerts(v);
    });
  }

  Future<void> _flushQueuedAlerts(List<ConnectivityResult> statuses) async {
    final online = statuses.any((r) => r != ConnectivityResult.none);
    if (!online) return;
    final api = CloudAlertApi();
    final n = await PendingCloudSync.flush(api);
    if (mounted && n > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(n == 1 ? 'Synced 1 queued alert.' : 'Synced $n queued alerts.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  bool get _hasNetwork =>
      _connectivity.any((r) => r != ConnectivityResult.none);

  bool get _dashboardEligible =>
      !Auth0Config.isConfigured || SessionController.instance.isAuthenticated;

  Future<void> _openPeopleFlowSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHeader(
                  title: 'Missing-person workflow',
                  subtitle: 'Create reports and review grouped sightings.',
                ),
                ListTile(
                  leading: const Icon(Icons.person_search_rounded),
                  title: const Text('Report missing person'),
                  subtitle: const Text('Submit structured details and last known info.'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PersonReportFormScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.groups_rounded),
                  title: const Text('View person reports'),
                  subtitle: const Text('Browse reports, groups, and likely matches.'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ReportsDisplayScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openVolunteerFlowSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHeader(
                  title: 'Volunteer and aid workflow',
                  subtitle: 'Collect needs, offers, donations, and run matching.',
                ),
                ListTile(
                  leading: const Icon(Icons.assignment_rounded),
                  title: const Text('Request / offer help'),
                  subtitle: const Text('Submit needs or volunteer offers.'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const VolunteerFormScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people_alt_rounded),
                  title: const Text('Volunteer matching dashboard'),
                  subtitle: const Text('Review needs/volunteers and run AI matching.'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const VolunteerDashboardScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final cloudDetail = _hasNetwork ? 'Online mode ready' : 'No network link';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            backgroundColor: ReliefNetApp.brandDeep,
            centerTitle: true,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'logo_final_relief.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ReliefNet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                      Shadow(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.28),
                        offset: const Offset(0, 0),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (Auth0Config.isConfigured)
                PopupMenuButton<String>(
                  tooltip: 'Account',
                  icon: Icon(
                    SessionController.instance.isAuthenticated
                        ? Icons.account_circle_rounded
                        : Icons.person_outline_rounded,
                  ),
                  onSelected: (value) async {
                    final sess = SessionController.instance;
                    if (value == 'logout') {
                      await sess.logout();
                    } else if (value == 'signin') {
                      await sess.switchFromGuestToLogin();
                    }
                  },
                  itemBuilder: (context) {
                    final sess = SessionController.instance;
                    final email = (sess.userEmail ?? '').trim();
                    final sub = (sess.userSub ?? '').trim();
                    final profileLine =
                        email.isNotEmpty ? email : (sub.isNotEmpty ? sub : 'Signed in');
                    return [
                      if (sess.isAuthenticated)
                        PopupMenuItem<String>(
                          enabled: false,
                          child: Text(profileLine),
                        ),
                      if (sess.isGuest)
                        const PopupMenuItem<String>(
                          value: 'signin',
                          child: Text('Sign in'),
                        ),
                      if (sess.isAuthenticated)
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Text('Log out'),
                        ),
                    ];
                  },
                ),
            ],
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
                const SizedBox(height: 18),
                Text(
                  'Quick actions',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const _SectionLabel('Emergency Alerts'),
                _ActionTile(
                  icon: Icons.emergency_rounded,
                  iconBackground: colorScheme.error.withValues(alpha: 0.18),
                  iconColor: colorScheme.error,
                  title: 'Submit SOS alert (online)',
                  subtitle: 'Send directly to cloud triage and responders.',
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
                  title: 'Submit SOS alert (offline)',
                  subtitle: 'Use laptop hub when internet is unavailable.',
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
                  icon: Icons.view_list_rounded,
                  iconBackground: colorScheme.primary.withValues(alpha: 0.18),
                  iconColor: colorScheme.primary,
                  title: 'All alerts feed',
                  subtitle: 'Unified stream of online + offline alerts.',
                  enabled: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AllAlertsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                const _SectionLabel('People & Incident Management'),
                _ActionTile(
                  icon: Icons.person_search_rounded,
                  iconBackground: colorScheme.primary.withValues(alpha: 0.18),
                  iconColor: colorScheme.primary,
                  title: 'Missing-person center',
                  subtitle: 'Create reports and review grouped sightings/matches.',
                  enabled: true,
                  onTap: _openPeopleFlowSheet,
                ),
                const SizedBox(height: 12),
                const _SectionLabel('Volunteer & Resource Workflow'),
                _ActionTile(
                  icon: Icons.people_alt_rounded,
                  iconBackground: colorScheme.primary.withValues(alpha: 0.18),
                  iconColor: colorScheme.primary,
                  title: 'Volunteer and aid center',
                  subtitle: 'Needs, offers, donations, and AI matching in one place.',
                  enabled: true,
                  onTap: _openVolunteerFlowSheet,
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
            '$label: ',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            stateLabel.isEmpty ? '-' : stateLabel,
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
    this.disabledSnackText,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final String? disabledSnackText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tileColor = Theme.of(context).colorScheme.surface.withValues(
          alpha: enabled ? 0.92 : 0.72,
        );

    return Material(
      color: tileColor,
      shadowColor: Colors.black.withValues(alpha: 0.6),
      elevation: enabled ? 0 : 8,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
          ),
        ],
      ),
    );
  }
}

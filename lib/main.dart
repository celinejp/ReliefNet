import 'package:flutter/material.dart';

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
                  onTap: () => _stubAction(context, 'SOS alert'),
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
        color: ReliefNetApp._brandDeep.withValues(alpha: 0.55),
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
            stateLabel,
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
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
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
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
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

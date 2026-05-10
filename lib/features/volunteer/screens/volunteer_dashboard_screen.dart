import 'package:flutter/material.dart';
import '../models/need_model.dart';
import '../models/volunteer_model.dart';
import '../models/donation_model.dart';
import '../models/match_model.dart';
import '../services/volunteer_service.dart';
import 'matches_screen.dart';

class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() => _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<NeedModel> _needs = [];
  List<VolunteerModel> _volunteers = [];
  List<DonationModel> _donations = [];
  List<MatchModel> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      VolunteerService.getNeeds(),
      VolunteerService.getVolunteers(),
      VolunteerService.getDonations(),
      VolunteerService.getMatches(),
    ]);
    if (!mounted) return;
    setState(() {
      _needs = results[0] as List<NeedModel>;
      _volunteers = results[1] as List<VolunteerModel>;
      _donations = results[2] as List<DonationModel>;
      _matches = results[3] as List<MatchModel>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text('Relief Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A202C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade400,
          isScrollable: true,
          tabs: [
            Tab(text: '🆘 Needs (${_needs.length})'),
            Tab(text: '🤝 Volunteers (${_volunteers.length})'),
            Tab(text: '💝 Donations (${_donations.length})'),
            Tab(text: '✨ Matches (${_matches.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _NeedsList(needs: _needs),
                _VolunteersList(volunteers: _volunteers),
                _DonationsList(donations: _donations),
                _MatchesList(matches: _matches, onRefresh: _loadAll),
              ],
            ),
    );
  }
}

class _NeedsList extends StatelessWidget {
  const _NeedsList({required this.needs});
  final List<NeedModel> needs;

  @override
  Widget build(BuildContext context) {
    if (needs.isEmpty) return _empty('No needs submitted yet.');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: needs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final n = needs[i];
        return _Card(
          leading: _urgencyColor(n.urgency),
          title: n.name,
          subtitle: n.categories.join(', '),
          trailing: _StatusBadge(n.status),
          detail: n.locationText.isNotEmpty ? '📍 ${n.locationText}' : null,
        );
      },
    );
  }

  Color _urgencyColor(String u) {
    switch (u) {
      case 'critical':
        return const Color(0xFFFC8181);
      case 'urgent':
        return const Color(0xFFF6AD55);
      default:
        return const Color(0xFF68D391);
    }
  }
}

class _VolunteersList extends StatelessWidget {
  const _VolunteersList({required this.volunteers});
  final List<VolunteerModel> volunteers;

  @override
  Widget build(BuildContext context) {
    if (volunteers.isEmpty) return _empty('No volunteers registered yet.');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: volunteers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final v = volunteers[i];
        return _Card(
          leading: const Color(0xFF68D391),
          title: v.name,
          subtitle: v.categories.join(', '),
          trailing: _StatusBadge(v.status),
          detail: v.locationText.isNotEmpty ? '📍 ${v.locationText}' : null,
        );
      },
    );
  }
}

class _DonationsList extends StatelessWidget {
  const _DonationsList({required this.donations});
  final List<DonationModel> donations;

  @override
  Widget build(BuildContext context) {
    if (donations.isEmpty) return _empty('No donations recorded yet.');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: donations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final d = donations[i];
        return _Card(
          leading: const Color(0xFFB794F4),
          title: d.donorName,
          subtitle: '${d.type} · ${d.amount}',
          trailing: null,
          detail: d.locationText.isNotEmpty ? '📍 ${d.locationText}' : null,
        );
      },
    );
  }
}

class _MatchesList extends StatelessWidget {
  const _MatchesList({required this.matches, required this.onRefresh});
  final List<MatchModel> matches;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✨', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('No matches yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const MatchesScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED8936),
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Matches Screen'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final m = matches[i];
        return _Card(
          leading: m.resolved ? const Color(0xFF68D391) : const Color(0xFFFC8181),
          title: '${m.need?.name ?? '?'} ↔ ${m.volunteer?.name ?? '?'}',
          subtitle: m.aiReason.isNotEmpty
              ? m.aiReason.length > 80
                  ? '${m.aiReason.substring(0, 80)}…'
                  : m.aiReason
              : 'Confidence: ${m.confidence}',
          trailing: _StatusBadge(m.resolved ? 'resolved' : 'pending'),
          detail: null,
        );
      },
    );
  }
}

Widget _empty(String msg) => Center(
      child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 15)),
    );

class _Card extends StatelessWidget {
  const _Card({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.detail,
  });

  final Color leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 48,
              decoration: BoxDecoration(
                color: leading,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF4A5568))),
                  if (detail != null) ...[
                    const SizedBox(height: 4),
                    Text(detail!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'matched':
      case 'resolved':
        bg = const Color(0xFFF0FFF4);
        fg = const Color(0xFF276749);
        break;
      case 'pending':
        bg = const Color(0xFFFFF5F5);
        fg = const Color(0xFFC53030);
        break;
      default:
        bg = const Color(0xFFEBF8FF);
        fg = const Color(0xFF2C7A7B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

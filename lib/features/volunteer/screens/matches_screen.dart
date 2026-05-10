import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/match_model.dart';
import '../services/volunteer_service.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<MatchModel> _matches = [];
  bool _loading = true;
  bool _matchingInProgress = false;
  String? _notificationMessage;
  Color _notificationColor = Colors.green;
  int _previousMatchCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() => _loading = true);
    final matches = await VolunteerService.getMatches();
    if (!mounted) return;
    setState(() {
      if (matches.length > _previousMatchCount && _previousMatchCount > 0) {
        _notificationMessage =
            '🎉 ${matches.length - _previousMatchCount} new match(es) found! People are being connected.';
        _notificationColor = const Color(0xFF276749);
      }
      _previousMatchCount = matches.length;
      _matches = matches;
      _loading = false;
    });
  }

  Future<void> _runMatching() async {
    setState(() {
      _matchingInProgress = true;
      _notificationMessage = null;
    });
    final result = await VolunteerService.runMatching();
    if (!mounted) return;
    setState(() => _matchingInProgress = false);
    if (result['success'] == true) {
      final message = result['message'] ?? 'Matching complete';
      final foundMatches = !message.contains('Found 0');
      setState(() {
        _notificationMessage = foundMatches
            ? '🎉 $message — Volunteers are being connected to people in need!'
            : 'ℹ️ No new matches found. More needs or volunteers required.';
        _notificationColor = foundMatches
            ? const Color(0xFF276749)
            : const Color(0xFF2B6CB0);
      });
      await _fetchMatches();
    } else {
      setState(() {
        _notificationMessage = '❌ Error running AI: ${result['message']}';
        _notificationColor = Colors.red.shade700;
      });
    }
  }

  Future<void> _resolveMatch(String matchId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Resolved?'),
        content: const Text(
            'Confirm that the volunteer successfully helped this person. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF276749),
                foregroundColor: Colors.white),
            child: const Text('Yes, Help Delivered'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await VolunteerService.resolveMatch(matchId);
      if (!mounted) return;
      if (success) {
        setState(() {
          _notificationMessage = '✅ Case resolved. Volunteer is now available again.';
          _notificationColor = const Color(0xFF276749);
        });
        _fetchMatches();
      }
    }
  }

  Future<void> _callPhone(String phone, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Call $name?'),
        content: Text('Opens your phone dialer to call $phone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3182CE),
                foregroundColor: Colors.white),
            child: const Text('📞 Call Now'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMatches = _matches.where((m) => !m.resolved).toList();
    final resolvedMatches = _matches.where((m) => m.resolved).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text('AI Volunteer Matches',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A202C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh list',
            onPressed: _fetchMatches,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_notificationMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    color: _notificationColor,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _notificationMessage!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(
                              () => _notificationMessage = null),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),

                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _statBox('${activeMatches.length}',
                          'Active', Colors.orange),
                      _statBox('${resolvedMatches.length}',
                          'Resolved', Colors.green),
                      _statBox(
                          '${_matches.length}', 'Total', Colors.blue),
                    ],
                  ),
                ),

                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      const Text('🤖 AI Matching Engine',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text(
                        'Claude AI compares all unmatched needs with available volunteers and finds the best pairs based on what is needed, location, and urgency level.',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _matchingInProgress
                              ? null
                              : _runMatching,
                          icon: _matchingInProgress
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            _matchingInProgress
                                ? 'AI is finding matches...'
                                : 'Find Matches with AI',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF3182CE),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: activeMatches.isEmpty && resolvedMatches.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchMatches,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (activeMatches.isNotEmpty) ...[
                                const _SectionHeader(
                                    label: 'Active Matches'),
                                ...activeMatches.map((m) => _MatchCard(
                                      match: m,
                                      onResolve: _resolveMatch,
                                      onCall: _callPhone,
                                    )),
                              ],
                              if (resolvedMatches.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const _SectionHeader(
                                    label: '✅ Resolved Cases',
                                    color: Colors.grey),
                                ...resolvedMatches.map((m) =>
                                    _MatchCard(
                                      match: m,
                                      onResolve: _resolveMatch,
                                      onCall: _callPhone,
                                      isResolved: true,
                                    )),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🤝', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              const Text('No Matches Yet',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const Text(
                'Steps to get matches:\n\n1️⃣  Someone submits a need\n2️⃣  A volunteer registers\n3️⃣  Tap "Find Matches with AI" above',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey, fontSize: 14, height: 1.7),
              ),
            ],
          ),
        ),
      );

  Widget _statBox(String num, String label, Color color) =>
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            border:
                Border(top: BorderSide(color: color, width: 3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(num,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader(
      {required this.label, this.color = const Color(0xFF1A202C)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color)),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchModel match;
  final Function(String) onResolve;
  final Function(String, String) onCall;
  final bool isResolved;

  const _MatchCard({
    required this.match,
    required this.onResolve,
    required this.onCall,
    this.isResolved = false,
  });

  Color get _confColor => switch (match.confidence) {
        'high' => const Color(0xFF276749),
        'medium' => const Color(0xFFB7791F),
        _ => const Color(0xFF9B2C2C),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isResolved
              ? Colors.grey.shade200
              : _confColor.withOpacity(0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isResolved ? Colors.grey.shade100 : _confColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Text('🤝 ',
                    style: TextStyle(fontSize: 16)),
                Text('Volunteer Match',
                    style: TextStyle(
                        color: isResolved ? Colors.grey.shade700 : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isResolved
                        ? Colors.grey.shade200
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isResolved
                        ? '✅ RESOLVED'
                        : '${match.confidence.toUpperCase()} MATCH',
                    style: TextStyle(
                        color: isResolved ? Colors.grey.shade700 : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (match.need != null)
                  _personCard(
                    emoji: '🆘',
                    role: 'NEEDS HELP',
                    roleColor: Colors.red,
                    name: match.need!.name,
                    phone: match.need!.phone,
                    tags: match.need!.categories,
                    location: match.need!.locationText,
                    urgency: match.need!.urgency,
                    onCall: () =>
                        onCall(match.need!.phone, match.need!.name),
                  ),

                if (match.need != null && match.volunteer != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.grey.shade200),
                          ),
                          child: const Text('matched with',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),

                if (match.volunteer != null)
                  _personCard(
                    emoji: '🤝',
                    role: 'CAN HELP',
                    roleColor: Colors.green,
                    name: match.volunteer!.name,
                    phone: match.volunteer!.phone,
                    tags: match.volunteer!.categories,
                    location: match.volunteer!.locationText,
                    onCall: () => onCall(
                        match.volunteer!.phone,
                        match.volunteer!.name),
                  ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🤖 ',
                          style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('Why AI matched them:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(match.aiReason,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4A5568),
                                    height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (!isResolved) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => onResolve(match.id),
                      icon: const Icon(
                          Icons.check_circle_outline,
                          size: 20),
                      label: const Text(
                          'Mark Resolved — Help Was Delivered',
                          style: TextStyle(
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF276749),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _personCard({
    required String emoji,
    required String role,
    required Color roleColor,
    required String name,
    required String phone,
    required List<String> tags,
    required String location,
    String? urgency,
    required VoidCallback onCall,
  }) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: roleColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: roleColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(role,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
                if (urgency == 'critical') ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('🔴 CRITICAL',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(name,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('📍 $location',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF2F7),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Text(t,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4A5568))),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.phone, size: 18),
                label: Text('Call $phone',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3182CE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/person_group_model.dart';
import '../models/person_report_model.dart';
import '../services/person_report_service.dart';

const _criticalRed = Color(0xFFE53E3E);
const _stableGreen = Color(0xFF38A169);
const _unknownGrey = Color(0xFF718096);
const _confHigh = Color(0xFF276749);
const _confMed = Color(0xFFB7791F);
const _confLow = Color(0xFF9B2C2C);
const _primaryBlue = Color(0xFF3182CE);

class ReportsDisplayScreen extends StatefulWidget {
  const ReportsDisplayScreen({super.key});

  @override
  State<ReportsDisplayScreen> createState() => _ReportsDisplayScreenState();
}

class _ReportsDisplayScreenState extends State<ReportsDisplayScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  Timer? _refreshTimer;

  bool _loading = true;
  List<PersonReport> _allReports = const [];
  List<PersonGroup> _groups = const [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _fetch();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetch(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        PersonReportService.getGroups(),
        PersonReportService.getAllReports(),
      ]);
      if (!mounted) return;
      setState(() {
        _groups = results[0] as List<PersonGroup>;
        _allReports = results[1] as List<PersonReport>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load: $e')),
      );
    }
  }

  Future<void> _resolve(String groupId) async {
    final ok = await PersonReportService.resolveGroup(groupId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group marked resolved')),
      );
      _fetch();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to resolve. Try again.')),
      );
    }
  }

  Future<void> _copyPhone(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $phone'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unresolved = _allReports.where((r) => !r.resolved).toList();
    final activeGroups = _groups.where((g) => !g.resolved).toList();
    final resolvedGroups = _groups.where((g) => g.resolved).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _fetch,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: [
            Tab(text: 'Matches (${activeGroups.length})'),
            Tab(text: 'Unmatched (${unresolved.length})'),
            Tab(text: 'All (${_allReports.length})'),
            Tab(text: 'Resolved (${resolvedGroups.length})'),
          ],
        ),
      ),
      body: _loading && _allReports.isEmpty && _groups.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _statsRow(activeGroups.length, unresolved.length,
                    resolvedGroups.length, _allReports.length),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _groupsList(activeGroups,
                          empty: 'No matches yet. Submit more reports.'),
                      _reportsList(unresolved,
                          empty: 'All reports have been matched.'),
                      _reportsList(_allReports,
                          empty: 'No reports submitted yet.'),
                      _groupsList(resolvedGroups,
                          empty: 'No resolved cases yet.'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statsRow(int matches, int unmatched, int resolved, int total) {
    Widget cell(String num, String label, Color accent) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border(top: BorderSide(color: accent, width: 3)),
          ),
          child: Column(
            children: [
              Text(num,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          cell('$matches', 'Matches', _criticalRed),
          cell('$unmatched', 'Unmatched', const Color(0xFFED8936)),
          cell('$resolved', 'Resolved', _stableGreen),
          cell('$total', 'Total', _primaryBlue),
        ],
      ),
    );
  }

  Widget _groupsList(List<PersonGroup> groups, {required String empty}) {
    if (groups.isEmpty) return _empty(empty);
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: groups.length,
        itemBuilder: (_, i) => _GroupCard(
          group: groups[i],
          onResolve: _resolve,
          onCopyPhone: _copyPhone,
        ),
      ),
    );
  }

  Widget _reportsList(List<PersonReport> reports, {required String empty}) {
    if (reports.isEmpty) return _empty(empty);
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: reports.length,
        itemBuilder: (_, i) => _ReportCard(
          report: reports[i],
          onCopyPhone: _copyPhone,
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      children: [
        Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatefulWidget {
  const _GroupCard({
    required this.group,
    required this.onResolve,
    required this.onCopyPhone,
  });

  final PersonGroup group;
  final Future<void> Function(String groupId) onResolve;
  final Future<void> Function(String phone) onCopyPhone;

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final confColor = _confidenceColor(g.confidence);
    final emerColor = _emergencyColor(g.highestEmergency);
    final emerLabel = _emergencyLabel(g.highestEmergency);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: confColor.withValues(alpha: 0.06),
        border: Border.all(color: confColor.withValues(alpha: 0.5), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '👤 ${g.reports.length} Reports — Likely Same Person',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(_expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Badge(
                label: '${g.confidence.toUpperCase()} CONFIDENCE',
                color: confColor,
              ),
              _Badge(label: emerLabel, color: emerColor),
              if (g.resolved) _Badge(label: '✅ Resolved', color: _unknownGrey),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            g.representativeName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (g.aiReason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '💬 ${g.aiReason}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                ),
              ),
            ),
          if (_expanded) ...[
            const Divider(height: 24),
            for (final r in g.reports)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InlineReport(
                  report: r,
                  onCopyPhone: widget.onCopyPhone,
                ),
              ),
            if (!g.resolved)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => widget.onResolve(g.id),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Resolved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _confHigh,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _InlineReport extends StatelessWidget {
  const _InlineReport({required this.report, required this.onCopyPhone});

  final PersonReport report;
  final Future<void> Function(String phone) onCopyPhone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                report.reportType == 'looking'
                    ? '🔍 Looking For'
                    : '👁️ Found/Saw',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                report.reporterName,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (report.descriptionText.isNotEmpty)
            Text(report.descriptionText,
                style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (report.approximateAge.isNotEmpty)
                _Chip(text: '🎂 ${report.approximateAge}'),
              if (report.locationText.isNotEmpty)
                _Chip(text: '📍 ${report.locationText}'),
              if (report.lastSeenAt != null)
                _Chip(
                    text:
                        '🕐 ${DateFormat('MMM d, y · h:mm a').format(report.lastSeenAt!)}'),
              if (report.isInjured)
                const _Chip(
                    text: '🩹 Injured',
                    bg: Color(0xFFFED7D7),
                    fg: Color(0xFF9B2C2C)),
              if (report.isUnconscious)
                const _Chip(
                    text: '😶 Unconscious',
                    bg: Color(0xFFFED7D7),
                    fg: Color(0xFF9B2C2C)),
            ],
          ),
          const SizedBox(height: 8),
          if (report.reporterPhone.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => onCopyPhone(report.reporterPhone),
              icon: const Icon(Icons.phone, size: 16),
              label: Text(report.reporterPhone),
            ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onCopyPhone});

  final PersonReport report;
  final Future<void> Function(String phone) onCopyPhone;

  @override
  Widget build(BuildContext context) {
    final emerColor = _emergencyColor(report.emergencyLevel);
    final emerLabel = _emergencyLabel(report.emergencyLevel);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                report.reportType == 'looking' ? '🔍 Looking' : '👁️ Found',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              _Badge(label: emerLabel, color: emerColor),
            ],
          ),
          const SizedBox(height: 6),
          if (report.descriptionText.isNotEmpty)
            Text(report.descriptionText),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (report.approximateAge.isNotEmpty)
                _Chip(text: '🎂 ${report.approximateAge}'),
              if (report.gender != 'unknown') _Chip(text: '👤 ${report.gender}'),
              if (report.locationText.isNotEmpty)
                _Chip(text: '📍 ${report.locationText}'),
              if (report.isInjured)
                const _Chip(
                    text: '🩹 Injured',
                    bg: Color(0xFFFED7D7),
                    fg: Color(0xFF9B2C2C)),
              if (report.isUnconscious)
                const _Chip(
                    text: '😶 Unconscious',
                    bg: Color(0xFFFED7D7),
                    fg: Color(0xFF9B2C2C)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '👤 ${report.reporterName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              if (report.reporterPhone.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => onCopyPhone(report.reporterPhone),
                  icon: const Icon(Icons.phone, size: 16),
                  label: Text(report.reporterPhone),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    this.bg = const Color(0xFF2D3748),
    this.fg = Colors.white,
  });

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12)),
    );
  }
}

Color _confidenceColor(String c) {
  switch (c) {
    case 'high':
      return _confHigh;
    case 'low':
      return _confLow;
    default:
      return _confMed;
  }
}

Color _emergencyColor(String e) {
  switch (e) {
    case 'critical':
      return _criticalRed;
    case 'stable':
      return _stableGreen;
    default:
      return _unknownGrey;
  }
}

String _emergencyLabel(String e) {
  switch (e) {
    case 'critical':
      return '🔴 CRITICAL';
    case 'stable':
      return '🟢 Stable';
    default:
      return '⚪ Unknown';
  }
}

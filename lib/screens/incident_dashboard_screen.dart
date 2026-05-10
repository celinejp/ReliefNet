import 'package:flutter/material.dart';

import '../models/cloud_incident.dart';
import '../services/cloud_alert_api.dart';
import '../widgets/severity_badge.dart';
import 'alert_detail_screen.dart';

enum _SeverityFilter { all, critical, medium, low }

class IncidentDashboardScreen extends StatefulWidget {
  const IncidentDashboardScreen({super.key});

  @override
  State<IncidentDashboardScreen> createState() => _IncidentDashboardScreenState();
}

class _IncidentDashboardScreenState extends State<IncidentDashboardScreen> {
  final _api = CloudAlertApi();

  late Future<List<CloudIncident>> _future;
  _SeverityFilter _filter = _SeverityFilter.all;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<CloudIncident>> _load() {
    final severity = switch (_filter) {
      _SeverityFilter.all => null,
      _SeverityFilter.critical => 'Critical',
      _SeverityFilter.medium => 'Medium',
      _SeverityFilter.low => 'Low',
    };
    return _api.listAlerts(severity: severity);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  void _onFilterChanged(_SeverityFilter next) {
    if (next == _filter) return;
    setState(() {
      _filter = next;
      _future = _load();
    });
  }

  String _timeLabel(DateTime? t) {
    if (t == null) return '';
    final local = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident dashboard'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filter == _SeverityFilter.all,
                  onSelected: (_) => _onFilterChanged(_SeverityFilter.all),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Critical'),
                  selected: _filter == _SeverityFilter.critical,
                  onSelected: (_) => _onFilterChanged(_SeverityFilter.critical),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Medium'),
                  selected: _filter == _SeverityFilter.medium,
                  onSelected: (_) => _onFilterChanged(_SeverityFilter.medium),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Low'),
                  selected: _filter == _SeverityFilter.low,
                  onSelected: (_) => _onFilterChanged(_SeverityFilter.low),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Sorted by Gemini severity, then newest.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: FutureBuilder<List<CloudIncident>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          'Could not load incidents.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                height: 1.45,
                              ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    );
                  }

                  final items = snapshot.data ?? const <CloudIncident>[];

                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          'No incidents in this view.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Submit an online SOS alert, change filters, or pull to refresh.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                height: 1.45,
                              ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final incident = items[index];
                      final title = incident.summary.isEmpty
                          ? incident.rawMessage
                          : incident.summary;

                      return Material(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    AlertDetailScreen(alertId: incident.id),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SeverityBadge(severity: incident.severity),
                                    const Spacer(),
                                    Text(
                                      _timeLabel(incident.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Colors.white
                                                .withValues(alpha: 0.55),
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  incident.category.isEmpty
                                      ? 'Category pending'
                                      : incident.category,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.72),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

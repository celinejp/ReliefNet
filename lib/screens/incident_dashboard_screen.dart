import 'package:flutter/material.dart';

import '../models/cloud_incident.dart';
import '../services/cloud_alert_api.dart';
import '../widgets/severity_badge.dart';

class IncidentDashboardScreen extends StatefulWidget {
  const IncidentDashboardScreen({super.key});

  @override
  State<IncidentDashboardScreen> createState() => _IncidentDashboardScreenState();
}

class _IncidentDashboardScreenState extends State<IncidentDashboardScreen> {
  final _api = CloudAlertApi();

  late Future<List<CloudIncident>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.listAlerts();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _api.listAlerts();
    });
    await _future;
  }

  void _showDetail(CloudIncident incident) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final pad = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + pad),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SeverityBadge(severity: incident.severity),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        incident.category.isEmpty
                            ? 'Uncategorized'
                            : incident.category,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Summary',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  incident.summary.isEmpty
                      ? '—'
                      : incident.summary,
                  style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Original message',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  incident.rawMessage,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
                if ((incident.aiError ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'AI error',
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    incident.aiError!,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.error,
                          height: 1.4,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Status: ${incident.processingStatus}',
                  style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      body: RefreshIndicator(
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
                    'No incidents yet.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submit an online SOS alert, then pull to refresh.',
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
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
                    onTap: () => _showDetail(incident),
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
                                      color: Colors.white.withValues(alpha: 0.55),
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
                                  color: Colors.white.withValues(alpha: 0.72),
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
    );
  }
}

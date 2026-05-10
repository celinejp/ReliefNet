import 'package:flutter/material.dart';

import '../models/cloud_incident.dart';
import '../services/cloud_alert_api.dart';
import '../widgets/severity_badge.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context) {
    final api = CloudAlertApi();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert detail'),
      ),
      body: FutureBuilder<CloudIncident>(
        future: api.getAlert(alertId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Could not load this alert.',
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
                ],
              ),
            );
          }

          final incident = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SeverityBadge(severity: incident.severity),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      incident.category.isEmpty
                          ? 'Uncategorized'
                          : incident.category,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Structured summary',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                incident.summary.isEmpty ? '—' : incident.summary,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 24),
              Text(
                'Original report',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                incident.rawMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              if ((incident.aiError ?? '').isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Claude processing error',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  incident.aiError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        height: 1.4,
                      ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Pipeline: ${incident.processingStatus}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

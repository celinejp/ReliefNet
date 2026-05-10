import 'package:flutter/material.dart';

import '../config/auth0_config.dart';
import '../models/cloud_incident.dart';
import '../services/cloud_alert_api.dart';
import '../services/session_controller.dart';
import '../widgets/severity_badge.dart';

class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final _api = CloudAlertApi();

  late Future<CloudIncident> _future;
  bool _patchBusy = false;

  @override
  void initState() {
    super.initState();
    _future = _api.getAlert(widget.alertId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _api.getAlert(widget.alertId);
    });
    await _future;
  }

  String _timeLabel(DateTime? t) {
    if (t == null) return '';
    final local = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _setResponderStatus(String next) async {
    setState(() => _patchBusy = true);
    try {
      await _api.patchResponderStatus(
        alertId: widget.alertId,
        responderStatus: next,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Responder status updated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _reload();
    } on CloudAlertApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _patchBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionController.instance;
    final showResponderTools =
        Auth0Config.isConfigured && session.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert detail'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _patchBusy ? null : _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<CloudIncident>(
        future: _future,
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
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
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
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_timeLabel(incident.createdAt).isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.schedule_rounded, size: 18),
                      label: Text(_timeLabel(incident.createdAt)),
                    ),
                  if ((incident.mode ?? '').isNotEmpty)
                    Chip(
                      avatar: Icon(
                        incident.mode == 'offline'
                            ? Icons.wifi_off_rounded
                            : Icons.cloud_outlined,
                        size: 18,
                      ),
                      label: Text(incident.mode == 'offline' ? 'Offline' : 'Online'),
                    ),
                  if (incident.guestMode == true)
                    Chip(
                      avatar: const Icon(Icons.person_off_outlined, size: 18),
                      label: const Text('Guest submission'),
                    ),
                ],
              ),
              if ((incident.location ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  incident.location!.trim(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.35),
                ),
              ],
              if ((incident.userEmail ?? '').trim().isNotEmpty ||
                  (incident.auth0UserId ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Reporter',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  [
                    if ((incident.userEmail ?? '').trim().isNotEmpty)
                      incident.userEmail!.trim(),
                    if ((incident.auth0UserId ?? '').trim().isNotEmpty)
                      incident.auth0UserId!.trim(),
                  ].join('\n'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ],
              if (showResponderTools) ...[
                const SizedBox(height: 24),
                Text(
                  'Responder status',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  incident.responderStatus ?? 'open',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Open'),
                      onPressed: _patchBusy
                          ? null
                          : () => _setResponderStatus('open'),
                    ),
                    ActionChip(
                      label: const Text('In progress'),
                      onPressed: _patchBusy
                          ? null
                          : () => _setResponderStatus('in_progress'),
                    ),
                    ActionChip(
                      label: const Text('Closed'),
                      onPressed: _patchBusy
                          ? null
                          : () => _setResponderStatus('closed'),
                    ),
                  ],
                ),
                Text(
                  'Accounts listed as admin/responder in Auth0 can change '
                  'status for everyone.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        height: 1.35,
                      ),
                ),
              ],
              const SizedBox(height: 24),
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

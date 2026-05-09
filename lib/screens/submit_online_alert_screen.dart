import 'package:flutter/material.dart';

import '../services/cloud_alert_api.dart';
import '../widgets/severity_badge.dart';

class SubmitOnlineAlertScreen extends StatefulWidget {
  const SubmitOnlineAlertScreen({super.key});

  @override
  State<SubmitOnlineAlertScreen> createState() => _SubmitOnlineAlertScreenState();
}

class _SubmitOnlineAlertScreenState extends State<SubmitOnlineAlertScreen> {
  final _controller = TextEditingController();
  final _api = CloudAlertApi();
  final _formKey = GlobalKey<FormState>();

  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      final incident = await _api.submitAlert(_controller.text.trim());
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Alert submitted'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SeverityBadge(severity: incident.severity),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          incident.processingStatus == 'failed'
                              ? 'AI processing failed — saved with error.'
                              : 'Claude triage complete.',
                          style: Theme.of(ctx).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    incident.category,
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    incident.summary.isEmpty
                        ? incident.rawMessage
                        : incident.summary,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                  ),
                  if ((incident.aiError ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      incident.aiError!,
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Done'),
              ),
            ],
          );
        },
      );

      if (mounted) _controller.clear();
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online SOS alert'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Describe what is happening. Claude will classify severity and '
                'normalize your report for responders.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    alignLabelWithHint: true,
                    labelText: 'Emergency details',
                    hintText:
                        'e.g. my father trapped building collapsed breathing issue',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.length < 8) {
                      return 'Add a bit more detail (at least 8 characters).';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(_submitting ? 'Sending…' : 'Send to cloud'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

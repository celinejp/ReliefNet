import 'package:flutter/material.dart';

class SeverityBadge extends StatelessWidget {
  const SeverityBadge({super.key, required this.severity});

  final String? severity;

  @override
  Widget build(BuildContext context) {
    final label = (severity == null || severity!.isEmpty)
        ? 'Unknown'
        : severity!;

    final scheme = Theme.of(context).colorScheme;
    late Color fg;
    late Color bg;

    switch (severity) {
      case 'Critical':
        fg = scheme.onErrorContainer;
        bg = scheme.errorContainer;
        break;
      case 'High':
        fg = scheme.onPrimaryContainer;
        bg = scheme.primaryContainer;
        break;
      case 'Medium':
        fg = scheme.onTertiaryContainer;
        bg = scheme.tertiaryContainer;
        break;
      case 'Low':
        fg = scheme.onSecondaryContainer;
        bg = scheme.secondaryContainer;
        break;
      default:
        fg = scheme.onSurfaceVariant;
        bg = scheme.surfaceContainerHighest;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

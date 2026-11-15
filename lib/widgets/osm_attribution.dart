import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => launchUrl(
          Uri.https('www.openstreetmap.org', '/copyright'),
          mode: LaunchMode.externalApplication,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            '© OpenStreetMap contributors',
            textDirection: TextDirection.ltr,
            style: theme.textTheme.labelSmall,
          ),
        ),
      ),
    );
  }
}

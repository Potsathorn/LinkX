import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/backdrop.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CornerFrame(
              color: Palette.navyEdge,
              length: 12,
              inset: -10,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Palette.navy,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Palette.navyLine),
                ),
                child: Icon(icon, size: 30, color: Palette.greyMuted),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTheme.hudLabel(color: Palette.white, size: 12),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Palette.greyMuted, height: 1.5),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

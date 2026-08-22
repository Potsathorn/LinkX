import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/action_result.dart';

void showActionResult(BuildContext context, ActionResult result) {
  if (!context.mounted || !result.shouldNotify) return;

  final Color accent = result.success ? Palette.grey : Palette.amber;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: Palette.navyRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: accent.withValues(alpha: 0.5)),
        ),
        content: Row(
          children: <Widget>[
            Container(
              width: 3,
              height: 26,
              decoration: BoxDecoration(
                color: accent,
                boxShadow: AppTheme.glow(accent, blur: 8, opacity: 0.6),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              result.success ? Icons.check_circle_outline : Icons.error_outline,
              size: 18,
              color: accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result.message,
                style: const TextStyle(color: Palette.white, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: result.success ? 2 : 4),
      ),
    );
}

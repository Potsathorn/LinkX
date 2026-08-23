import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.accent = Palette.amber,
  });

  final String title;
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 10),
      child: Row(
        children: <Widget>[
          Container(width: 3, height: 14, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: AppTheme.hudLabel(color: Palette.grey, size: 11),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/history_entry.dart';

class RecentList extends StatelessWidget {
  const RecentList({
    super.key,
    required this.entries,
    required this.onRelaunch,
  });

  final List<HistoryEntry> entries;
  final ValueChanged<HistoryEntry> onRelaunch;

  static IconData iconFor(LinkAction action) => switch (action) {
        LinkAction.generated => Icons.content_copy,
        LinkAction.launched => Icons.rocket_launch,
        LinkAction.shared => Icons.ios_share,
        LinkAction.qrSaved => Icons.qr_code_2,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final HistoryEntry entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RecentTile(
              entry: entry,
              onTap: () => onRelaunch(entry),
            ),
          ),
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.entry, required this.onTap});

  final HistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.navy,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Palette.navyLine),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                RecentList.iconFor(entry.action),
                size: 14,
                color: Palette.greyMuted,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.mono(context, size: 11)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormatter.relative(entry.timestamp),
                          style: AppTheme.hudLabel(size: 8.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.mono(context, size: 10.5)
                          .copyWith(color: Palette.greyMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.replay, size: 15, color: Palette.amber),
            ],
          ),
        ),
      ),
    );
  }
}

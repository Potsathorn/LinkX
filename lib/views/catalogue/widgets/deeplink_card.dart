import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/channel_label.dart';
import '../../../data/models/deeplink_entry.dart';
import '../../widgets/spec_chips.dart';

class DeeplinkCard extends StatelessWidget {
  const DeeplinkCard({
    super.key,
    required this.entry,
    required this.usageCount,
    required this.onTap,
    this.highlight = '',
  });

  final DeeplinkEntry entry;
  final int usageCount;
  final VoidCallback onTap;
  final String highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  RankBadge(rank: entry.rank),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _HighlightedText(
                          text: entry.primaryDestination,
                          query: highlight,
                          style: AppTheme.mono(context, size: 12).copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                        if (entry.extraDestinationCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              '+${entry.extraDestinationCount} more '
                              'destination${entry.extraDestinationCount == 1 ? '' : 's'}',
                              style: AppTheme.hudLabel(size: 8.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (usageCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text(
                        '${usageCount}x',
                        style:
                            AppTheme.hudLabel(color: Palette.amber, size: 9.5),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              TerminalBlock(text: entry.pathPattern, maxLines: 3),
              const SizedBox(height: 9),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: <Widget>[
                        for (final ChannelLabel label in entry.labels)
                          ChannelChip(label: label, dense: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  UserTypeStrip(types: entry.allowedUserTypes),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    this.style,
  });

  final String text;
  final String query;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final String q = query.trim().toLowerCase();
    final int start = q.isEmpty ? -1 : text.toLowerCase().indexOf(q);

    if (start < 0) {
      return Text(text,
          style: style, maxLines: 2, overflow: TextOverflow.ellipsis);
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: <InlineSpan>[
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, start + q.length),
            style: const TextStyle(
              color: Palette.black,
              backgroundColor: Palette.amber,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: text.substring(start + q.length)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/history_entry.dart';
import '../../widgets/spec_chips.dart';

enum HistoryTileAction { relaunch, edit, copy, delete }

class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.entry,
    required this.onAction,
  });

  final HistoryEntry entry;
  final ValueChanged<HistoryTileAction> onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Map<String, String> params = entry.link.appliedParameters;

    return Card(
      child: InkWell(
        onTap: () => onAction(HistoryTileAction.edit),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _ActionBadge(action: entry.action),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    DateFormatter.relative(entry.timestamp),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  PopupMenuButton<HistoryTileAction>(
                    tooltip: 'More actions',
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    onSelected: onAction,
                    itemBuilder: (BuildContext context) =>
                        const <PopupMenuEntry<HistoryTileAction>>[
                      PopupMenuItem<HistoryTileAction>(
                        value: HistoryTileAction.relaunch,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.rocket_launch_outlined, size: 18),
                          title: Text('Launch again'),
                        ),
                      ),
                      PopupMenuItem<HistoryTileAction>(
                        value: HistoryTileAction.edit,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined, size: 18),
                          title: Text('Edit in generator'),
                        ),
                      ),
                      PopupMenuItem<HistoryTileAction>(
                        value: HistoryTileAction.copy,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.copy_all_outlined, size: 18),
                          title: Text('Copy link'),
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem<HistoryTileAction>(
                        value: HistoryTileAction.delete,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline, size: 18),
                          title: Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 4),
                child: TerminalBlock(text: entry.url, maxLines: 2),
              ),
              if (params.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final MapEntry<String, String> e
                        in params.entries.take(4))
                      _ParamPill(label: '${e.key}=${e.value}'),
                    if (params.length > 4)
                      _ParamPill(label: '+${params.length - 4} more'),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  RankBadge(rank: entry.link.rank, compact: true),
                  const SizedBox(width: 6),
                  if (entry.link.testedUserType != null)
                    UserTypeChip(type: entry.link.testedUserType!),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => onAction(HistoryTileAction.relaunch),
                    icon: const Icon(Icons.replay, size: 15),
                    label: const Text('Re-launch'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.action});
  final LinkAction action;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (action) {
      LinkAction.generated => (Icons.content_copy, Palette.greyMuted),
      LinkAction.launched => (Icons.rocket_launch, Palette.amber),
      LinkAction.shared => (Icons.ios_share, Palette.greyMuted),
      LinkAction.qrSaved => (Icons.qr_code_2, Palette.greyMuted),
    };

    return Tooltip(
      message: action.label,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Icon(icon, size: 13, color: color),
      ),
    );
  }
}

class _ParamPill extends StatelessWidget {
  const _ParamPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Palette.amber.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Palette.amber.withValues(alpha: 0.22)),
      ),
      constraints: const BoxConstraints(maxWidth: 190),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.mono(context, size: 10).copyWith(color: Palette.amber),
      ),
    );
  }
}

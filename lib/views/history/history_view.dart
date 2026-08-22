import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/action_result.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/history_entry.dart';
import '../../viewmodels/generator_viewmodel.dart';
import '../../viewmodels/history_viewmodel.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/search_field.dart';
import 'widgets/history_tile.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  Future<void> _handle(
    BuildContext context,
    HistoryViewModel vm,
    HistoryEntry entry,
    HistoryTileAction action,
  ) async {
    switch (action) {
      case HistoryTileAction.relaunch:
        final ActionResult result = await vm.relaunch(entry);
        if (context.mounted) showActionResult(context, result);

      case HistoryTileAction.edit:
        final bool restored =
            context.read<GeneratorViewModel>().loadHistoryEntry(entry);
        if (!restored) {
          showActionResult(
            context,
            const ActionResult.error(
              'That deeplink is no longer in the spec file.',
            ),
          );
          return;
        }
        context.go(AppRoute.generator.path);

      case HistoryTileAction.copy:
        final ActionResult result = await vm.copy(entry);
        if (context.mounted) showActionResult(context, result);

      case HistoryTileAction.delete:
        final ActionResult result = await vm.delete(entry);
        if (context.mounted) showActionResult(context, result);
    }
  }

  Future<void> _confirmClear(
    BuildContext context,
    HistoryViewModel vm,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Clear history?'),
        content: Text(
          'All ${vm.totalCount} logged link(s) will be removed.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final ActionResult result = await vm.clearAll();
    if (context.mounted) showActionResult(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final HistoryViewModel vm = context.watch<HistoryViewModel>();
    final Map<DateTime, List<HistoryEntry>> grouped = vm.groupedByDay;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Clear history',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: vm.isEmpty ? null : () => _confirmClear(context, vm),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SearchField(
              hintText: 'Search deeplinks, params or values',
              initialValue: vm.query,
              onChanged: vm.search,
            ),
          ),
          Expanded(
            child: grouped.isEmpty
                ? EmptyState(
                    icon: vm.isEmpty
                        ? Icons.history_toggle_off
                        : Icons.search_off,
                    title: vm.isEmpty ? 'No history yet' : 'Nothing matches',
                    message: vm.isEmpty
                        ? 'Deeplinks you run are logged here.'
                        : 'Try a different search term.',
                    action: vm.isEmpty
                        ? FilledButton.tonalIcon(
                            onPressed: () =>
                                context.go(AppRoute.catalogue.path),
                            icon:
                                const Icon(Icons.dashboard_customize_outlined),
                            label: const Text('Open catalogue'),
                          )
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: grouped.length,
                    itemBuilder: (BuildContext context, int index) {
                      final DateTime day = grouped.keys.elementAt(index);
                      final List<HistoryEntry> entries = grouped[day]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _DayHeader(day: day, count: entries.length),
                          for (final HistoryEntry entry in entries)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Dismissible(
                                key: ValueKey<String>(entry.id),
                                direction: DismissDirection.endToStart,
                                background: const _DeleteBackground(),
                                onDismissed: (_) => _handle(
                                  context,
                                  vm,
                                  entry,
                                  HistoryTileAction.delete,
                                ),
                                child: HistoryTile(
                                  entry: entry,
                                  onAction: (HistoryTileAction action) =>
                                      _handle(context, vm, entry, action),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.count});
  final DateTime day;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime now = DateTime.now();
    final bool isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
      child: Row(
        children: <Widget>[
          Text(
            (isToday ? 'Today' : DateFormatter.full(day).split(',').first)
                .toUpperCase(),
            style: AppTheme.hudLabel(color: Palette.grey, size: 10),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Palette.amberDeep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Palette.amber.withValues(alpha: 0.5)),
      ),
      child: const Icon(Icons.delete_outline, color: Palette.amber),
    );
  }
}

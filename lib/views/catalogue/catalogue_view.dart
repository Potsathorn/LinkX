import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/action_result.dart';
import '../../data/models/deeplink_entry.dart';
import '../../viewmodels/catalogue_viewmodel.dart';
import '../../viewmodels/generator_viewmodel.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/search_field.dart';
import 'widgets/deeplink_card.dart';
import 'widgets/most_used_section.dart';

class CatalogueView extends StatelessWidget {
  const CatalogueView({super.key});

  void _open(BuildContext context, DeeplinkEntry entry) {
    context.read<GeneratorViewModel>().loadEntry(entry);
    context.go(AppRoute.generator.path);
  }

  @override
  Widget build(BuildContext context) {
    final CatalogueViewModel vm = context.watch<CatalogueViewModel>();
    final List<DeeplinkEntry> entries = vm.entries;
    final bool narrowed = vm.isSearching || vm.isFiltering;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              floating: true,
              title: Row(
                children: <Widget>[
                  const Text('Deeplinks'),
                  if (vm.isExampleSpec) ...<Widget>[
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => context.push(AppRoute.spec.path),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Palette.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DEMO SPEC',
                          style:
                              AppTheme.hudLabel(color: Palette.black, size: 9),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: <Widget>[
                _FilterButton(active: vm.isFiltering),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: SearchField(
                  hintText: 'Search page, path or parameter',
                  initialValue: vm.query,
                  onChanged: vm.search,
                ),
              ),
            ),
            if (narrowed)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 16, 10),
                  child: Text(
                    '${entries.length} of ${vm.totalCount}',
                    style: AppTheme.hudLabel(size: 9.5),
                  ),
                ),
              ),
            if (!narrowed && vm.mostUsed.isNotEmpty)
              SliverToBoxAdapter(
                child: MostUsedSection(
                  ranked: vm.mostUsed,
                  onTap: (RankedEntry ranked) => _open(context, ranked.entry),
                  onReset: () async {
                    final ActionResult result = await vm.resetUsageStats();
                    if (context.mounted) showActionResult(context, result);
                  },
                ),
              ),
            if (entries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.search_off,
                  title: 'No match',
                  message: 'Clear the search or filter.',
                  action: FilledButton(
                    onPressed: vm.clearFilters,
                    child: const Text('Clear filters'),
                  ),
                ),
              )
            else
              SliverList.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) {
                  final DeeplinkEntry entry = entries[index];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      index == entries.length - 1 ? 24 : 0,
                    ),
                    child: DeeplinkCard(
                      entry: entry,
                      usageCount: vm.usageCount(entry.id),
                      highlight: vm.query,
                      onTap: () => _open(context, entry),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Filter',
      onPressed: () => context.push(AppRoute.filters.path),
      icon: Icon(
        active ? Icons.filter_alt : Icons.filter_alt_outlined,
        color: active ? Palette.amber : Palette.grey,
      ),
    );
  }
}

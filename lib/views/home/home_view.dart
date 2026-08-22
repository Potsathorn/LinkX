import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/action_result.dart';
import '../../data/models/deeplink_entry.dart';
import '../../data/models/history_entry.dart';
import '../../viewmodels/catalogue_viewmodel.dart';
import '../../viewmodels/generator_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../catalogue/widgets/deeplink_card.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/section_header.dart';
import '../widgets/share_origin.dart';
import 'widgets/launcher_card.dart';
import 'widgets/recent_list.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  Future<void> _run(BuildContext context, Future<ActionResult> action) async {
    final ActionResult result = await action;
    if (context.mounted) showActionResult(context, result);
  }

  void _openEntry(BuildContext context, DeeplinkEntry entry) {
    context.read<GeneratorViewModel>().loadEntry(entry);
    context.go(AppRoute.generator.path);
  }

  @override
  Widget build(BuildContext context) {
    final HomeViewModel vm = context.watch<HomeViewModel>();
    final CatalogueViewModel catalogue = context.watch<CatalogueViewModel>();
    final List<DeeplinkEntry> top = vm.topRanked;

    return Scaffold(
      appBar: AppBar(title: const Text('LinkX')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: <Widget>[
          Builder(
            builder: (BuildContext buttonContext) => LauncherCard(
              vm: vm,
              onLaunch: () => _run(context, vm.launch()),
              onQr: () => context.push(AppRoute.qr.path, extra: vm.link),
              onShare: () => _run(
                context,
                vm.shareUrl(origin: shareOriginOf(buttonContext)),
              ),
            ),
          ),
          if (vm.hasRecent) ...<Widget>[
            const SectionHeader(title: 'Recent'),
            RecentList(
              entries: vm.recent,
              onRelaunch: (HistoryEntry entry) =>
                  _run(context, vm.relaunch(entry)),
            ),
          ],
          if (top.isNotEmpty) ...<Widget>[
            const SectionHeader(title: 'Top links'),
            for (final DeeplinkEntry entry in top)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DeeplinkCard(
                  entry: entry,
                  usageCount: catalogue.usageCount(entry.id),
                  onTap: () => _openEntry(context, entry),
                ),
              ),
          ],
          if (top.isEmpty && !vm.hasRecent)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                'Load a spec to see ranked deeplinks here.',
                textAlign: TextAlign.center,
                style: AppTheme.hudLabel(size: 9.5),
              ),
            ),
        ],
      ),
    );
  }
}

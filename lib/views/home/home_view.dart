import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/action_result.dart';
import '../../data/models/deeplink_entry.dart';
import '../../data/models/generated_link.dart';
import '../../data/models/history_entry.dart';
import '../../data/models/onelink_config.dart';
import '../../viewmodels/catalogue_viewmodel.dart';
import '../../viewmodels/generator_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/onelink_viewmodel.dart';
import '../../services/link_action_runner.dart';
import '../../services/onelink_service.dart';
import '../catalogue/widgets/deeplink_card.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/onelink_card.dart';
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

  Future<void> _runOneLink(
    BuildContext context,
    Future<ActionResult> Function(GeneratedLink link) action,
  ) async {
    final GeneratedOneLink? generated =
        context.read<HomeOneLinkViewModel>().generated;
    if (generated == null) return;

    final ActionResult result =
        await action(GeneratedLink.adHoc(generated.url));
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
    final OneLinkViewModel oneLink = context.watch<HomeOneLinkViewModel>();
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
          const SizedBox(height: 14),
          Builder(
            builder: (BuildContext buttonContext) => OneLinkCard(
              vm: oneLink,
              onGenerate: () async {
                final OneLinkOutcome outcome = await oneLink.generate();
                if (!context.mounted || outcome.isSuccess) return;
                showActionResult(context, ActionResult.error(outcome.message));
              },
              onCopy: () => _runOneLink(
                  context,
                  (GeneratedLink l) =>
                      context.read<LinkActionRunner>().copy(l)),
              onLaunch: () => _runOneLink(
                  context,
                  (GeneratedLink l) =>
                      context.read<LinkActionRunner>().launch(l)),
              onShare: () => _runOneLink(
                context,
                (GeneratedLink l) => context.read<LinkActionRunner>().shareUrl(
                      l,
                      origin: shareOriginOf(buttonContext),
                    ),
              ),
              onQr: () {
                final GeneratedOneLink? generated = oneLink.generated;
                if (generated == null) return;
                context.push(
                  AppRoute.qr.path,
                  extra: GeneratedLink.adHoc(generated.url),
                );
              },
            ),
          ),
          if (vm.hasRecent) ...<Widget>[
            SectionHeader(
              title: 'Recent',
              trailing: TextButton(
                onPressed: () => context.go(AppRoute.history.path),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  'FULL HISTORY',
                  style: AppTheme.hudLabel(color: Palette.amber, size: 9),
                ),
              ),
            ),
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/action_result.dart';
import '../../../data/models/generated_link.dart';
import '../../../data/models/onelink_config.dart';
import '../../../services/link_action_runner.dart';
import '../../../services/onelink_service.dart';
import '../../../viewmodels/onelink_viewmodel.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/onelink_card.dart';
import '../../widgets/share_origin.dart';

class GeneratorOneLinkSheet extends StatelessWidget {
  const GeneratorOneLinkSheet({super.key});

  Future<void> _run(
    BuildContext context,
    Future<ActionResult> Function(GeneratedLink link) action,
  ) async {
    final GeneratedOneLink? generated =
        context.read<GeneratorOneLinkViewModel>().generated;
    if (generated == null) return;

    final ActionResult result =
        await action(GeneratedLink.adHoc(generated.url));
    if (context.mounted) showActionResult(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final GeneratorOneLinkViewModel vm =
        context.watch<GeneratorOneLinkViewModel>();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(
                  'ONELINK',
                  style: AppTheme.hudLabel(color: Palette.white, size: 12),
                ),
              ),
              Builder(
                builder: (BuildContext buttonContext) => OneLinkCard(
                  vm: vm,
                  notReadyMessage:
                      'Fill in every required parameter first — Launch is still disabled.',
                  onGenerate: () async {
                    final OneLinkOutcome outcome = await vm.generate();
                    if (!context.mounted || outcome.isSuccess) return;
                    showActionResult(
                        context, ActionResult.error(outcome.message));
                  },
                  onCopy: () => _run(
                    context,
                    (GeneratedLink l) =>
                        context.read<LinkActionRunner>().copy(l),
                  ),
                  onLaunch: () => _run(
                    context,
                    (GeneratedLink l) =>
                        context.read<LinkActionRunner>().launch(l),
                  ),
                  onShare: () => _run(
                    context,
                    (GeneratedLink l) =>
                        context.read<LinkActionRunner>().shareUrl(
                              l,
                              origin: shareOriginOf(buttonContext),
                            ),
                  ),
                  onQr: () {
                    final GeneratedOneLink? generated = vm.generated;
                    if (generated == null) return;
                    context.push(
                      AppRoute.qr.path,
                      extra: GeneratedLink.adHoc(generated.url),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

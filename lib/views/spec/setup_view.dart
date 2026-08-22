import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/backdrop.dart';
import '../../core/utils/action_result.dart';
import '../../viewmodels/spec_viewmodel.dart';
import '../widgets/app_snackbar.dart';
import 'widgets/paste_spec_dialog.dart';

class SetupView extends StatelessWidget {
  const SetupView({super.key});

  Future<void> _import(BuildContext context, SpecViewModel vm) async {
    final ActionResult result = await vm.importFromFile();
    if (!context.mounted) return;

    showActionResult(context, result);
    if (result.success && !result.silent) context.go(AppRoute.home.path);
  }

  Future<void> _paste(BuildContext context, SpecViewModel vm) async {
    final String? raw = await PasteSpecDialog.show(context);
    if (raw == null || !context.mounted) return;

    final ActionResult result = await vm.importFromText(raw);
    if (!context.mounted) return;

    showActionResult(context, result);
    if (result.success && !result.silent) context.go(AppRoute.home.path);
  }

  @override
  Widget build(BuildContext context) {
    final SpecViewModel vm = context.watch<SpecViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CornerFrame(
                  color: Palette.navyEdge,
                  length: 14,
                  inset: -12,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Palette.navy,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Palette.navyLine),
                    ),
                    child: const Icon(Icons.upload_file,
                        size: 34, color: Palette.amber),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'LOAD A DEEPLINK SPEC',
                  textAlign: TextAlign.center,
                  style: AppTheme.hudLabel(color: Palette.white, size: 13),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pick the spec JSON for the build you are testing. '
                  'It is stored on this device only, and you can replace it '
                  'any time from the catalogue.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Palette.grey, height: 1.6),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: vm.isBusy ? null : () => _import(context, vm),
                  icon: vm.isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.folder_open, size: 18),
                  label: const Text('Choose spec file'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: vm.isBusy ? null : () => _paste(context, vm),
                  icon: const Icon(Icons.content_paste, size: 18),
                  label: const Text('Paste JSON'),
                ),
                const SizedBox(height: 22),
                TextButton(
                  onPressed: vm.isBusy
                      ? null
                      : () async {
                          await vm.acceptExample();
                          if (context.mounted) {
                            context.go(AppRoute.home.path);
                          }
                        },
                  child: Text(
                    'Continue with the example spec',
                    style: AppTheme.hudLabel(size: 9.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

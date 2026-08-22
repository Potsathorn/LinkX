import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/action_result.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/datasources/deeplink_spec_source.dart';
import '../../viewmodels/spec_viewmodel.dart';
import '../widgets/app_snackbar.dart';
import 'widgets/paste_spec_dialog.dart';

class SpecSheet extends StatelessWidget {
  const SpecSheet({super.key});

  Future<void> _handle(
    BuildContext context,
    Future<ActionResult> action,
  ) async {
    final ActionResult result = await action;
    if (!context.mounted) return;

    showActionResult(context, result);
    if (result.success && !result.silent) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final SpecViewModel vm = context.watch<SpecViewModel>();
    final bool isExample = vm.origin == SpecOrigin.example;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('DEEPLINK SPEC',
                style: AppTheme.hudLabel(color: Palette.white, size: 12)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Palette.navy,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isExample ? Palette.amber : Palette.navyLine,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Row(label: 'SOURCE', value: vm.origin.label),
                  _Row(label: 'FILE', value: vm.label),
                  _Row(label: 'DEEPLINKS', value: '${vm.entryCount}'),
                  if (vm.importedAt != null)
                    _Row(
                      label: 'LOADED',
                      value: DateFormatter.relative(vm.importedAt!),
                    ),
                ],
              ),
            ),
            if (isExample) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.warning_amber_rounded,
                      size: 15, color: Palette.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'These are example deeplinks, not the real spec.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Palette.amber, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: vm.isBusy
                  ? null
                  : () => _handle(context, vm.importFromFile()),
              icon: vm.isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.folder_open, size: 18),
              label: Text(isExample ? 'Choose spec file' : 'Replace spec'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: vm.isBusy
                  ? null
                  : () async {
                      final String? raw = await PasteSpecDialog.show(context);
                      if (raw == null || !context.mounted) return;
                      await _handle(context, vm.importFromText(raw));
                    },
              icon: const Icon(Icons.content_paste, size: 18),
              label: const Text('Paste JSON'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 84,
            child: Text(label, style: AppTheme.hudLabel(size: 9)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.mono(context, size: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

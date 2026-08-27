import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/action_result.dart';
import '../../data/models/deeplink_entry.dart';
import '../../data/models/link_parameter.dart';
import '../../viewmodels/generator_viewmodel.dart';
import '../../viewmodels/onelink_viewmodel.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import 'widgets/link_preview_card.dart';
import 'widgets/parameter_field.dart';

class GeneratorView extends StatelessWidget {
  const GeneratorView({super.key});

  @override
  Widget build(BuildContext context) {
    final GeneratorViewModel vm = context.watch<GeneratorViewModel>();
    final DeeplinkEntry? entry = vm.entry;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Generator',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Deeplink info',
            icon: const Icon(Icons.info_outline),
            onPressed: entry == null
                ? null
                : () => context.push(AppRoute.entryInfo.path),
          ),
          IconButton(
            tooltip: 'Clear the selection',
            icon: const Icon(Icons.restart_alt),
            onPressed: entry == null ? null : vm.reset,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: entry == null
          ? EmptyState(
              icon: Icons.link_off,
              title: 'No deeplink selected',
              message: 'Pick one from the catalogue.',
              action: FilledButton.tonalIcon(
                onPressed: () => context.go(AppRoute.catalogue.path),
                icon: const Icon(Icons.dashboard_customize_outlined),
                label: const Text('Open catalogue'),
              ),
            )
          : _GeneratorForm(vm: vm, entry: entry),
    );
  }
}

class _GeneratorForm extends StatelessWidget {
  const _GeneratorForm({required this.vm, required this.entry});

  final GeneratorViewModel vm;
  final DeeplinkEntry entry;

  Future<void> _run(
    BuildContext context,
    Future<ActionResult> Function() action,
  ) async {
    final ActionResult result = await action();
    if (context.mounted) showActionResult(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final GeneratorOneLinkViewModel oneLink =
        context.watch<GeneratorOneLinkViewModel>();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.42,
            ),
            child: LinkPreviewCard(
              url: vm.url,
              validation: vm.validation,
              isBusy: vm.isBusy,
              onUrlChanged: vm.editUrl,
              onUrlRevert: vm.revertUrl,
              isUrlEdited: vm.isUrlEdited,
              onCopy: () => _run(context, vm.copyToClipboard),
              onShare: (Rect? origin) =>
                  _run(context, () => vm.shareUrl(origin: origin)),
              onLaunch: () => _run(context, vm.launch),
              onQr: () => context.push(AppRoute.qr.path, extra: vm.link),
              onOneLink: oneLink.isConfigured
                  ? () => context.push(AppRoute.oneLink.path)
                  : null,
              isOneLinkEnabled: oneLink.isEligible,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Palette.navy.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: <Widget>[
                if (!entry.hasParameters)
                  const _NoParametersHint()
                else ...<Widget>[
                  _ParameterGroup(
                    title: 'Required',
                    accent: Palette.amber,
                    parameters: vm.requiredParameters,
                    vm: vm,
                  ),
                  _ParameterGroup(
                    title: 'Conditional',
                    accent: Palette.amber,
                    parameters: vm.conditionalParameters,
                    vm: vm,
                  ),
                  _ParameterGroup(
                    title: 'Optional',
                    accent: Palette.greyMuted,
                    parameters: vm.optionalParameters,
                    vm: vm,
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ParameterGroup extends StatelessWidget {
  const _ParameterGroup({
    required this.title,
    required this.accent,
    required this.parameters,
    required this.vm,
  });

  final String title;
  final Color accent;
  final List<LinkParameter> parameters;
  final GeneratorViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (parameters.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: '$title (${parameters.length})',
          accent: accent,
        ),
        for (final LinkParameter p in parameters)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ParameterField(
              key: ValueKey<String>('${vm.entry?.id}:${p.name}'),
              parameter: p,
              onChanged: (String value) => vm.updateParameter(p.name, value),
              onToggled: (bool enabled) => vm.toggleParameter(p.name, enabled),
            ),
          ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _NoParametersHint extends StatelessWidget {
  const _NoParametersHint();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Palette.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.check_circle_outline,
              size: 17, color: Palette.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No parameters — ready to launch.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Palette.grey, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

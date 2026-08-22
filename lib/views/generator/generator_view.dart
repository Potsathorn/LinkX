import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/action_result.dart';
import '../../data/models/deeplink_entry.dart';
import '../../data/models/link_parameter.dart';
import '../../viewmodels/generator_viewmodel.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/share_origin.dart';
import 'widgets/entry_header_card.dart';
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
      bottomNavigationBar: entry == null ? null : _ActionBar(vm: vm),
    );
  }
}

class _GeneratorForm extends StatelessWidget {
  const _GeneratorForm({required this.vm, required this.entry});

  final GeneratorViewModel vm;
  final DeeplinkEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: <Widget>[
        EntryHeaderCard(
          entry: entry,
          variant: vm.variant,
          testedUserType: vm.testedUserType,
          onVariantSelected: vm.selectVariant,
          onUserTypeSelected: vm.setTestedUserType,
        ),
        const SizedBox(height: 16),
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
        LinkPreviewCard(
          url: vm.url,
          validation: vm.validation,
          onCopy: () async {
            final ActionResult result = await vm.copyToClipboard();
            if (context.mounted) showActionResult(context, result);
          },
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

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.vm});

  final GeneratorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final bool enabled = vm.hasLink && !vm.isBusy;

    return Container(
      decoration: const BoxDecoration(
        color: Palette.black,
        border: Border(top: BorderSide(color: Palette.navyEdge)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: enabled
                        ? AppTheme.glow(Palette.amber, blur: 18, opacity: 0.4)
                        : null,
                  ),
                  child: FilledButton.icon(
                    onPressed: enabled
                        ? () async {
                            final ActionResult result = await vm.launch();
                            if (context.mounted) {
                              showActionResult(context, result);
                            }
                          }
                        : null,
                    icon: vm.isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.rocket_launch_outlined, size: 18),
                    label: const Text('Launch'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed:
                      enabled ? () => context.push(AppRoute.qr.path) : null,
                  icon: const Icon(Icons.qr_code_2, size: 18),
                  label: const Text('QR'),
                ),
              ),
              const SizedBox(width: 10),
              Builder(
                builder: (BuildContext buttonContext) => IconButton.filledTonal(
                  tooltip: 'Share the deeplink',
                  onPressed: enabled
                      ? () async {
                          final ActionResult result = await vm.shareUrl(
                            origin: shareOriginOf(buttonContext),
                          );
                          if (context.mounted) {
                            showActionResult(context, result);
                          }
                        }
                      : null,
                  icon: const Icon(Icons.ios_share, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

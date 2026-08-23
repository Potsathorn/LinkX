import 'package:flutter/material.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/onelink_config.dart';
import '../../viewmodels/onelink_viewmodel.dart';
import 'spec_chips.dart';

class OneLinkCard extends StatelessWidget {
  const OneLinkCard({
    super.key,
    required this.vm,
    required this.onGenerate,
    required this.onCopy,
    required this.onLaunch,
    required this.onShare,
    required this.onQr,
    this.notReadyMessage,
  });

  final OneLinkViewModel vm;
  final VoidCallback onGenerate;
  final VoidCallback onCopy;
  final VoidCallback onLaunch;
  final VoidCallback onShare;
  final VoidCallback onQr;
  final String? notReadyMessage;

  @override
  Widget build(BuildContext context) {
    if (!vm.isConfigured) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Palette.navy,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Palette.navyEdge),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('ONELINK', style: AppTheme.hudLabel(size: 9.5)),
              const SizedBox(width: 8),
              Text(
                'AppsFlyer',
                style: AppTheme.hudLabel(color: Palette.greyMuted, size: 8.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!vm.isEligible)
            _Notice(
              icon: Icons.info_outline,
              text: notReadyMessage ??
                  'Available once the link above starts with '
                      '${AppConfig.deeplinkPrefix}',
            )
          else ...<Widget>[
            Text('ENVIRONMENT', style: AppTheme.hudLabel(size: 8.5)),
            const SizedBox(height: 9),
            Row(
              children: <Widget>[
                for (final OneLinkEnvironment option in vm.environments) ...[
                  Expanded(
                    child: _EnvOption(
                      label: option.env,
                      selected: vm.env == option.env,
                      onTap: () => vm.selectEnvironment(option.env),
                    ),
                  ),
                  if (option != vm.environments.last) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: vm.canGenerate ? onGenerate : null,
                icon: vm.isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  vm.env == null ? 'Choose an environment' : 'Generate OneLink',
                ),
              ),
            ),
          ],
          if (vm.error != null) ...<Widget>[
            const SizedBox(height: 14),
            _Notice(
                icon: Icons.warning_amber_rounded,
                text: vm.error!,
                tone: Palette.amber),
          ],
          if (vm.generated != null) ...<Widget>[
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _Result(
              link: vm.generated!,
              reused: vm.wasReused,
              onCopy: onCopy,
              onLaunch: onLaunch,
              onShare: onShare,
              onQr: onQr,
            ),
          ],
        ],
      ),
    );
  }
}

class _EnvOption extends StatelessWidget {
  const _EnvOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Palette.amber : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? Palette.amber : Palette.navyEdge,
            ),
          ),
          child: Text(
            label,
            style: AppTheme.hudLabel(
              color: selected ? Palette.black : Palette.grey,
              size: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.link,
    required this.reused,
    required this.onCopy,
    required this.onLaunch,
    required this.onShare,
    required this.onQr,
  });

  final GeneratedOneLink link;
  final bool reused;
  final VoidCallback onCopy;
  final VoidCallback onLaunch;
  final VoidCallback onShare;
  final VoidCallback onQr;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Palette.amber,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(link.env,
                  style: AppTheme.hudLabel(color: Palette.black, size: 9)),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                reused ? 'Reused from cache' : 'Generated now',
                style: AppTheme.hudLabel(size: 8.5),
              ),
            ),
            Text(
              DateFormatter.relative(link.createdAt),
              style: AppTheme.hudLabel(size: 8.5),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TerminalBlock(text: link.url, maxLines: 4, prefix: '↗'),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: onLaunch,
                icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                label: const Text('Launch'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: onQr,
                child: const Text('QR'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: onShare,
                child: const Text('Share'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_all_outlined, size: 16),
            label: const Text('Copy OneLink'),
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.text,
    this.tone = Palette.greyMuted,
  });

  final IconData icon;
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 15, color: tone),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: tone, fontSize: 11.5, height: 1.5),
          ),
        ),
      ],
    );
  }
}

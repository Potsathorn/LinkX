import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/home_viewmodel.dart';

class LauncherCard extends StatelessWidget {
  const LauncherCard({
    super.key,
    required this.vm,
    required this.onLaunch,
    required this.onQr,
    required this.onShare,
  });

  final HomeViewModel vm;
  final VoidCallback onLaunch;
  final VoidCallback onQr;
  final VoidCallback onShare;

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final String? text = data?.text?.trim();
    if (text != null && text.isNotEmpty) vm.setLink(text);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = vm.canLaunch;

    return Container(
      decoration: BoxDecoration(
        color: Palette.navy,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Palette.navyLine),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('LAUNCHER', style: AppTheme.hudLabel(size: 9.5)),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Paste',
                icon: const Icon(Icons.content_paste, size: 17),
                onPressed: _paste,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Share',
                icon: const Icon(Icons.share, size: 17),
                onPressed: vm.isEmpty ? null : onShare,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Clear',
                icon: const Icon(Icons.backspace_outlined, size: 17),
                onPressed: vm.isEmpty ? null : vm.clear,
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: vm.linkController,
            maxLines: 3,
            minLines: 2,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            style: AppTheme.mono(context, size: 12),
            decoration: InputDecoration(
              hintText: 'Paste any deeplink or OneLink to test',
              errorText: vm.validationMessage,
              errorMaxLines: 2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: enabled ? onLaunch : null,
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
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: enabled ? onQr : null,
                  icon: const Icon(Icons.qr_code_2, size: 18),
                  label: const Text('QR'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

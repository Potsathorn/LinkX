import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/backdrop.dart';
import '../../core/utils/action_result.dart';
import '../../data/models/generated_link.dart';
import '../../services/link_action_runner.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/share_origin.dart';
import '../widgets/spec_chips.dart';

class QrSheet extends StatefulWidget {
  const QrSheet({super.key, required this.link});

  final GeneratedLink? link;

  @override
  State<QrSheet> createState() => _QrSheetState();
}

class _QrSheetState extends State<QrSheet> {
  bool _isBusy = false;

  Future<void> _run(Future<ActionResult> Function() action) async {
    if (_isBusy) return;

    setState(() => _isBusy = true);
    try {
      final ActionResult result = await action();
      if (mounted) showActionResult(context, result);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final GeneratedLink? link = widget.link;

    if (link == null || link.url.trim().isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            'There is no link to encode yet.',
            textAlign: TextAlign.center,
            style: AppTheme.hudLabel(size: 10),
          ),
        ),
      );
    }

    final LinkActionRunner runner = context.read<LinkActionRunner>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'QR code',
              style: AppTheme.hudLabel(color: Palette.white, size: 13),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                link.destinationPage,
                style: AppTheme.mono(context, size: 11)
                    .copyWith(color: Palette.grey),
              ),
            ),
            const SizedBox(height: 18),
            CornerFrame(
              length: 20,
              inset: -12,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow:
                      AppTheme.glow(Palette.amber, blur: 30, opacity: 0.22),
                ),
                child: QrImageView(
                  data: link.url,
                  version: QrVersions.auto,
                  size: 220,
                  gapless: true,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                  errorStateBuilder: (BuildContext context, Object? error) =>
                      const SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'This link is too long to encode as a QR code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Palette.amber, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TerminalBlock(text: link.url, maxLines: 3),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isBusy
                        ? null
                        : () => _run(() => runner.saveQrToGallery(link)),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Builder(
                    builder: (BuildContext buttonContext) => FilledButton.icon(
                      onPressed: _isBusy
                          ? null
                          : () => _run(() => runner.shareQrImage(
                                link,
                                origin: shareOriginOf(buttonContext),
                              )),
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: const Text('Share QR'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (BuildContext buttonContext) => TextButton.icon(
                onPressed: _isBusy
                    ? null
                    : () => _run(() => runner.shareUrl(
                          link,
                          origin: shareOriginOf(buttonContext),
                        )),
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Share the raw URL instead'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

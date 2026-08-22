import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/backdrop.dart';
import '../../core/utils/action_result.dart';
import '../../viewmodels/generator_viewmodel.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/spec_chips.dart';
import '../widgets/share_origin.dart';

class QrSheet extends StatelessWidget {
  const QrSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final GeneratorViewModel vm = context.watch<GeneratorViewModel>();

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
            if (vm.entry != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  vm.entry!.destinationPage,
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
                      AppTheme.glow(Palette.amber, blur: 34, opacity: 0.28),
                ),
                child: QrImageView(
                  data: vm.url,
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
            TerminalBlock(text: vm.url, maxLines: 3),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: vm.isBusy
                        ? null
                        : () async {
                            final ActionResult result =
                                await vm.saveQrToGallery();
                            if (context.mounted) {
                              showActionResult(context, result);
                            }
                          },
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Builder(
                    builder: (BuildContext buttonContext) => FilledButton.icon(
                      onPressed: vm.isBusy
                          ? null
                          : () async {
                              final ActionResult result = await vm.shareQrImage(
                                origin: shareOriginOf(buttonContext),
                              );
                              if (context.mounted) {
                                showActionResult(context, result);
                              }
                            },
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
                onPressed: vm.isBusy
                    ? null
                    : () async {
                        final ActionResult result = await vm.shareUrl(
                          origin: shareOriginOf(buttonContext),
                        );
                        if (context.mounted) showActionResult(context, result);
                      },
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

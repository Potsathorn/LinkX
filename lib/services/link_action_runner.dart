import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/utils/action_result.dart';
import '../data/models/generated_link.dart';
import '../data/models/history_entry.dart';
import '../data/repositories/history_repository.dart';
import '../data/repositories/usage_repository.dart';
import 'launcher_service.dart';
import 'qr_service.dart';
import 'share_service.dart';

class LinkActionRunner {
  const LinkActionRunner({
    required QrService qrService,
    required ShareService shareService,
    required LauncherService launcher,
    required HistoryRepository historyRepository,
    required UsageRepository usageRepository,
  })  : _qrService = qrService,
        _shareService = shareService,
        _launcher = launcher,
        _historyRepository = historyRepository,
        _usageRepository = usageRepository;

  final QrService _qrService;
  final ShareService _shareService;
  final LauncherService _launcher;
  final HistoryRepository _historyRepository;
  final UsageRepository _usageRepository;

  Future<ActionResult> copy(GeneratedLink link) =>
      _record(link, LinkAction.generated, () async {
        await Clipboard.setData(ClipboardData(text: link.url));
        return const ActionResult.ok('Link copied to the clipboard.');
      });

  Future<ActionResult> launch(GeneratedLink link) =>
      _record(link, LinkAction.launched, () async {
        final LaunchResult result = await _launcher.launch(link.url);
        return result.isSuccess
            ? const ActionResult.ok('Opening the link…')
            : ActionResult.error(result.message);
      });

  Future<ActionResult> shareUrl(GeneratedLink link, {Rect? origin}) =>
      _record(link, LinkAction.shared, () async {
        final ShareResult result =
            await _shareService.shareUrl(link, origin: origin);
        return _fromShare(result, 'Link shared.');
      });

  Future<ActionResult> shareQrImage(GeneratedLink link, {Rect? origin}) =>
      _record(link, LinkAction.shared, () async {
        final ShareResult result =
            await _shareService.shareQrImage(link, origin: origin);
        return _fromShare(result, 'QR code shared.');
      });

  Future<ActionResult> saveQrToGallery(GeneratedLink link) =>
      _record(link, LinkAction.qrSaved, () async {
        final QrSaveResult result = await _qrService.saveToGallery(
          link.url,
          fileName: fileNameFor(link),
        );
        return result.isSuccess
            ? ActionResult.ok(result.message)
            : ActionResult.error(result.message);
      });

  Future<ActionResult> _record(
    GeneratedLink link,
    LinkAction action,
    Future<ActionResult> Function() body,
  ) async {
    if (link.url.trim().isEmpty) {
      return const ActionResult.error('There is no link to use yet.');
    }

    final ActionResult result = await body();
    if (result.success && !result.silent) {
      await _historyRepository.add(link, action);
      await _usageRepository.increment(link.entryId);
    }
    return result;
  }

  ActionResult _fromShare(ShareResult result, String successMessage) {
    return switch (result.status) {
      ShareResultStatus.success => ActionResult.ok(successMessage),
      ShareResultStatus.dismissed => const ActionResult.none(),
      ShareResultStatus.unavailable => ActionResult.ok(successMessage),
    };
  }

  static String fileNameFor(GeneratedLink link) {
    final String slug = link.destinationPage
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'linkx_qr_${slug}_${DateTime.now().millisecondsSinceEpoch}';
  }
}

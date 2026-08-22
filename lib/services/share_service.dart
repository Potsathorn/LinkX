import 'dart:ui';

import 'package:share_plus/share_plus.dart';

import '../data/models/generated_link.dart';
import 'qr_service.dart';

class ShareService {
  const ShareService(this._qrService);
  final QrService _qrService;

  Future<ShareResult> shareUrl(GeneratedLink link, {Rect? origin}) {
    return SharePlus.instance.share(
      ShareParams(
        text: link.url,
        subject: link.destinationPage,
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<ShareResult> shareQrImage(GeneratedLink link, {Rect? origin}) async {
    final String path = await _qrService.writeTempPng(link.url);

    return SharePlus.instance.share(
      ShareParams(
        text: link.url,
        subject: link.destinationPage,
        files: <XFile>[XFile(path, mimeType: 'image/png')],
        sharePositionOrigin: origin,
      ),
    );
  }
}

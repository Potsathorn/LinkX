import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum QrSaveStatus { saved, permissionDenied, notEnoughSpace, failed }

@immutable
class QrSaveResult {
  const QrSaveResult(this.status, this.message);
  final QrSaveStatus status;
  final String message;

  bool get isSuccess => status == QrSaveStatus.saved;
}

class QrService {
  const QrService();
  static const String albumName = 'LinkX';
  static const double defaultExportSize = 1024;

  QrPainter painter(
    String data, {
    Color foreground = Colors.black,
    int errorCorrectionLevel = QrErrorCorrectLevel.M,
  }) {
    return QrPainter(
      data: data.isEmpty ? ' ' : data,
      version: QrVersions.auto,
      errorCorrectionLevel: errorCorrectionLevel,
      gapless: true,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: foreground,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: foreground,
      ),
    );
  }

  Future<Uint8List> generatePng(
    String data, {
    double size = defaultExportSize,
    double quietZone = 48,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size, size),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size, size),
      Paint()..color = Colors.white,
    );

    final double inner = size - (quietZone * 2);
    canvas.save();
    canvas.translate(quietZone, quietZone);
    painter(data).paint(canvas, Size(inner, inner));
    canvas.restore();

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    try {
      final ByteData? bytes =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('Failed to encode the QR code as PNG.');
      }
      return bytes.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  Future<QrSaveResult> saveToGallery(
    String data, {
    String? fileName,
    double size = defaultExportSize,
  }) async {
    try {
      final Uint8List bytes = await generatePng(data, size: size);

      if (!await Gal.hasAccess(toAlbum: true)) {
        final bool granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          return const QrSaveResult(
            QrSaveStatus.permissionDenied,
            'Photo library access denied — enable it in Settings to save QR codes.',
          );
        }
      }

      await Gal.putImageBytes(
        bytes,
        album: albumName,
        name: fileName ?? _timestampedName(),
      );

      return const QrSaveResult(
        QrSaveStatus.saved,
        'QR code saved to your gallery ("$albumName").',
      );
    } on GalException catch (e) {
      return QrSaveResult(_statusFor(e.type), _messageFor(e.type));
    } catch (e) {
      return QrSaveResult(
          QrSaveStatus.failed, 'Could not save the QR code: $e');
    }
  }

  Future<String> writeTempPng(
    String data, {
    String? fileName,
    double size = defaultExportSize,
  }) async {
    final Uint8List bytes = await generatePng(data, size: size);
    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}/${fileName ?? _timestampedName()}.png');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String _timestampedName() =>
      'linkx_qr_${DateTime.now().millisecondsSinceEpoch}';

  QrSaveStatus _statusFor(GalExceptionType type) => switch (type) {
        GalExceptionType.accessDenied => QrSaveStatus.permissionDenied,
        GalExceptionType.notEnoughSpace => QrSaveStatus.notEnoughSpace,
        _ => QrSaveStatus.failed,
      };

  String _messageFor(GalExceptionType type) => switch (type) {
        GalExceptionType.accessDenied =>
          'Photo library access denied — enable it in Settings to save QR codes.',
        GalExceptionType.notEnoughSpace =>
          'Not enough storage space to save the QR code.',
        GalExceptionType.notSupportedFormat =>
          'The generated image format is not supported by this device.',
        GalExceptionType.unexpected =>
          'Something went wrong while saving the QR code.',
      };
}

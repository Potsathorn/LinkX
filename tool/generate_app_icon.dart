import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const double kCanvas = 1024;

const Color kVoid = Color(0xFF0D0D0D);
const Color kCore = Color(0xFF1A1A1A);
const Color kAmber = Color(0xFFF08A16);
const Color kInk = Color(0xFFFFFFFF);

void paintBackground(Canvas canvas, {required bool detail}) {
  const Rect rect = Rect.fromLTWH(0, 0, kCanvas, kCanvas);

  canvas.drawRect(
    rect,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.35),
        radius: 1.15,
        colors: <Color>[kCore, kVoid],
      ).createShader(rect),
  );
}

void paintReticle(Canvas canvas, {required double alpha}) {
  const double inset = 152;
  const double arm = 92;
  final Paint paint = Paint()
    ..color = kAmber.withValues(alpha: alpha)
    ..strokeWidth = 20
    ..strokeCap = StrokeCap.butt
    ..strokeJoin = StrokeJoin.miter
    ..style = PaintingStyle.stroke;

  const double lo = inset;
  const double hi = kCanvas - inset;

  final Path path = Path()
    ..moveTo(lo + arm, lo)
    ..lineTo(lo, lo)
    ..lineTo(lo, lo + arm)
    ..moveTo(hi - arm, lo)
    ..lineTo(hi, lo)
    ..lineTo(hi, lo + arm)
    ..moveTo(lo, hi - arm)
    ..lineTo(lo, hi)
    ..lineTo(lo + arm, hi)
    ..moveTo(hi - arm, hi)
    ..lineTo(hi, hi)
    ..lineTo(hi, hi - arm);

  canvas.drawPath(path, paint);
}

const double kDiagonal = 0.7853981633974483;
const double kCentre = kCanvas / 2;

Offset _alongUpRight(double distance) => Offset(
      kCentre + distance * 0.7071067811865476,
      kCentre - distance * 0.7071067811865476,
    );

void _slashSegment(
  Canvas canvas, {
  required double from,
  required double to,
  required Paint paint,
}) {
  canvas.save();
  canvas.translate(kCentre, kCentre);
  canvas.rotate(kDiagonal);
  canvas.drawLine(Offset(from, 0), Offset(to, 0), paint);
  canvas.restore();
}

void _chainRing(
  Canvas canvas, {
  required Offset centre,
  required double scale,
  required Paint paint,
}) {
  final double length = 344 * scale;
  final double width = 186 * scale;

  canvas.save();
  canvas.translate(centre.dx, centre.dy);
  canvas.rotate(-kDiagonal);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: length, height: width),
      Radius.circular(width / 2),
    ),
    paint,
  );
  canvas.restore();
}

Paint _stroke(Color color, double width, {StrokeCap cap = StrokeCap.butt}) =>
    Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = cap
      ..style = PaintingStyle.stroke;

void paintMark(Canvas canvas, {required double scale, required bool detail}) {
  if (scale <= 0) return;

  if (!detail) {
    final double bar = 126 * scale;
    _slashSegment(
      canvas,
      from: -352 * scale,
      to: 352 * scale,
      paint: _stroke(kInk, bar, cap: StrokeCap.round),
    );
    canvas.save();
    canvas.translate(kCentre, kCentre);
    canvas.rotate(-kDiagonal);
    canvas.drawLine(
      Offset(-352 * scale, 0),
      Offset(352 * scale, 0),
      _stroke(kAmber, bar, cap: StrokeCap.round),
    );
    canvas.restore();
    return;
  }

  final double barWidth = 104 * scale;
  final double ringStroke = 58 * scale;
  final Offset amberCentre = _alongUpRight(-172 * scale);
  final Offset whiteCentre = _alongUpRight(172 * scale);

  _slashSegment(
    canvas,
    from: -400 * scale,
    to: -60 * scale,
    paint: _stroke(kInk, barWidth),
  );
  _slashSegment(
    canvas,
    from: 60 * scale,
    to: 400 * scale,
    paint: _stroke(kInk, barWidth),
  );

  _chainRing(
    canvas,
    centre: whiteCentre,
    scale: scale,
    paint: _stroke(kInk, ringStroke),
  );
  _chainRing(
    canvas,
    centre: amberCentre,
    scale: scale,
    paint: _stroke(kAmber, ringStroke),
  );

  canvas.save();
  canvas.clipRect(const Rect.fromLTWH(kCentre, 0, kCentre, kCentre));
  _chainRing(
    canvas,
    centre: whiteCentre,
    scale: scale,
    paint: _stroke(kInk, ringStroke),
  );
  canvas.restore();
}

Future<Uint8List> render(
  double pixels, {
  required bool withBackground,
  required bool detail,
  double markScale = 1,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  canvas.scale(pixels / kCanvas);

  if (withBackground) {
    paintBackground(canvas, detail: detail);
  }
  paintMark(canvas, scale: markScale, detail: detail);

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(pixels.round(), pixels.round());
  try {
    final ByteData bytes =
        (await image.toByteData(format: ui.ImageByteFormat.png))!;
    return bytes.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

Future<void> write(String path, Uint8List bytes) async {
  final File file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
  stdout.writeln('${path.padRight(72)} ${bytes.length ~/ 1024} KB');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate app icons', () async {
    const Map<String, double> ios = <String, double>{
      'Icon-App-20x20@1x.png': 20,
      'Icon-App-20x20@2x.png': 40,
      'Icon-App-20x20@3x.png': 60,
      'Icon-App-29x29@1x.png': 29,
      'Icon-App-29x29@2x.png': 58,
      'Icon-App-29x29@3x.png': 87,
      'Icon-App-40x40@1x.png': 40,
      'Icon-App-40x40@2x.png': 80,
      'Icon-App-40x40@3x.png': 120,
      'Icon-App-60x60@2x.png': 120,
      'Icon-App-60x60@3x.png': 180,
      'Icon-App-76x76@1x.png': 76,
      'Icon-App-76x76@2x.png': 152,
      'Icon-App-83.5x83.5@2x.png': 167,
      'Icon-App-1024x1024@1x.png': 1024,
    };

    for (final MapEntry<String, double> entry in ios.entries) {
      final bool detail = entry.value >= 120;
      await write(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/${entry.key}',
        await render(
          entry.value,
          withBackground: true,
          detail: detail,
          markScale: detail ? 1 : 1.12,
        ),
      );
    }

    const Map<String, double> androidLegacy = <String, double>{
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };

    for (final MapEntry<String, double> entry in androidLegacy.entries) {
      final bool detail = entry.value >= 144;
      await write(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
        await render(
          entry.value,
          withBackground: true,
          detail: detail,
          markScale: detail ? 1 : 1.12,
        ),
      );
    }

    const Map<String, double> adaptive = <String, double>{
      'mdpi': 108,
      'hdpi': 162,
      'xhdpi': 216,
      'xxhdpi': 324,
      'xxxhdpi': 432,
    };

    for (final MapEntry<String, double> entry in adaptive.entries) {
      final bool detail = entry.value >= 216;
      await write(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher_background.png',
        await render(entry.value,
            withBackground: true, detail: detail, markScale: 0),
      );
      await write(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher_foreground.png',
        await render(entry.value,
            withBackground: false, detail: detail, markScale: 0.95),
      );
    }
  });
}

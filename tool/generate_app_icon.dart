import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const double kCanvas = 1024;

const Color kVoid = Color(0xFF000000);
const Color kCore = Color(0xFF14213D);
const Color kCyan = Color(0xFFFCA311);
const Color kInk = Color(0xFFE4E4E4);

void paintBackground(Canvas canvas, {required bool detail}) {
  const Rect rect = Rect.fromLTWH(0, 0, kCanvas, kCanvas);

  canvas.drawRect(
    rect,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.15, -0.3),
        radius: 1.05,
        colors: <Color>[kCore, kVoid],
      ).createShader(rect),
  );

  if (!detail) return;

  final Paint minor = Paint()
    ..color = kCore.withValues(alpha: 0.55)
    ..strokeWidth = 2;
  final Paint major = Paint()
    ..color = kCore
    ..strokeWidth = 2.5;

  int i = 0;
  for (double p = 0; p <= kCanvas; p += 64) {
    final Paint paint = i % 4 == 0 ? major : minor;
    canvas.drawLine(Offset(p, 0), Offset(p, kCanvas), paint);
    canvas.drawLine(Offset(0, p), Offset(kCanvas, p), paint);
    i++;
  }
}

void paintReticle(Canvas canvas, {required double alpha}) {
  const double inset = 152;
  const double arm = 92;
  final Paint paint = Paint()
    ..color = kCyan.withValues(alpha: alpha)
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

void _chainLink(
  Canvas canvas, {
  required double rotation,
  required double scale,
  required Paint paint,
}) {
  const double centre = kCanvas / 2;
  final double length = 700 * scale;
  final double width = 196 * scale;

  canvas.save();
  canvas.translate(centre, centre);
  canvas.rotate(rotation);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: length, height: width),
      Radius.circular(width / 2),
    ),
    paint,
  );
  canvas.restore();
}

void _solidBar(
  Canvas canvas, {
  required double rotation,
  required double scale,
  required Paint paint,
}) {
  const double centre = kCanvas / 2;
  final double arm = 214 * scale;

  canvas.save();
  canvas.translate(centre, centre);
  canvas.rotate(rotation);
  canvas.drawLine(Offset(-arm, 0), Offset(arm, 0), paint);
  canvas.restore();
}

Paint _ringPaint(Color color, double stroke) => Paint()
  ..color = color
  ..strokeWidth = stroke
  ..style = PaintingStyle.stroke;

Paint _barPaint(Color color, double stroke) => Paint()
  ..color = color
  ..strokeWidth = stroke
  ..strokeCap = StrokeCap.round;

void paintMark(Canvas canvas, {required double scale, required bool detail}) {
  if (scale <= 0) return;

  const double centre = kCanvas / 2;
  final double stroke = (detail ? 62 : 96) * scale;

  void draw(double rotation, Paint paint) {
    if (detail) {
      _chainLink(canvas, rotation: rotation, scale: scale, paint: paint);
    } else {
      _solidBar(canvas, rotation: rotation, scale: scale, paint: paint);
    }
  }

  if (detail) {
    draw(
      -kDiagonal,
      Paint()
        ..color = kCyan.withValues(alpha: 0.5)
        ..strokeWidth = stroke * 1.7
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.7),
    );
  }

  final Paint ink = detail ? _ringPaint(kInk, stroke) : _barPaint(kInk, stroke);
  final Paint cyan =
      detail ? _ringPaint(kCyan, stroke) : _barPaint(kCyan, stroke);

  draw(kDiagonal, ink);
  draw(-kDiagonal, cyan);

  canvas.save();
  canvas.clipRect(const Rect.fromLTWH(0, 0, centre, centre));
  draw(kDiagonal, ink);
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
    if (detail) paintReticle(canvas, alpha: 0.55);
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

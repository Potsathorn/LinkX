import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ReticlePainter extends CustomPainter {
  const ReticlePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final double arm = size.shortestSide * 0.34 * progress;
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.85 * progress)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(Offset.zero, Offset(arm, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, arm), paint);

    canvas.drawLine(Offset(size.width - arm, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, arm), paint);

    canvas.drawLine(
        Offset(0, size.height - arm), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(arm, size.height), paint);

    canvas.drawLine(Offset(size.width - arm, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - arm),
        Offset(size.width, size.height), paint);

    final double tickAlpha = math.max(0.0, progress * 2 - 1);
    if (tickAlpha > 0) {
      final Paint tick = Paint()
        ..color = color.withValues(alpha: 0.5 * tickAlpha)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(size.width / 2, -6),
        Offset(size.width / 2, -14),
        tick,
      );
      canvas.drawLine(
        Offset(size.width / 2, size.height + 6),
        Offset(size.width / 2, size.height + 14),
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ReticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class ScanSweepPainter extends CustomPainter {
  const ScanSweepPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final double y = size.height * progress;
    const double band = 120;
    final Rect rect = Rect.fromLTWH(0, y - band, size.width, band * 2);

    final Paint paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.16),
          color.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant ScanSweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class TracePainter extends CustomPainter {
  const TracePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final double y = size.height / 2;
    final double head = size.width * progress;
    final Rect rect = Rect.fromLTWH(0, 0, math.max(head, 1), size.height);

    canvas.drawLine(
      Offset(0, y),
      Offset(head, y),
      Paint()
        ..strokeWidth = 1.4
        ..shader = LinearGradient(
          colors: <Color>[
            color.withValues(alpha: 0),
            color.withValues(alpha: 0.9),
          ],
        ).createShader(rect),
    );

    if (progress < 1) {
      canvas.drawCircle(
        Offset(head, y),
        3,
        Paint()..color = color,
      );
      canvas.drawCircle(
        Offset(head, y),
        9,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TracePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class ProgressLinePainter extends CustomPainter {
  const ProgressLinePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final double y = size.height / 2;

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = Palette.navyLine
        ..strokeWidth = 1,
    );

    if (progress <= 0) return;

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width * progress, y),
      Paint()
        ..color = Palette.amber
        ..strokeWidth = 1.6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
  }

  @override
  bool shouldRepaint(covariant ProgressLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

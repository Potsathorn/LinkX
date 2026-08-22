import 'package:flutter/material.dart';

import 'app_theme.dart';

class FuturisticBackdrop extends StatelessWidget {
  const FuturisticBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Palette.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const RepaintBoundary(
            child: CustomPaint(painter: _GridPainter()),
          ),
          child,
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  static const double _cell = 34;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint minor = Paint()
      ..color = Palette.navy.withValues(alpha: 0.30)
      ..strokeWidth = 1;
    final Paint major = Paint()
      ..color = Palette.navy.withValues(alpha: 0.55)
      ..strokeWidth = 1;

    int index = 0;
    for (double x = 0; x <= size.width; x += _cell) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        index % 4 == 0 ? major : minor,
      );
      index++;
    }

    index = 0;
    for (double y = 0; y <= size.height; y += _cell) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        index % 4 == 0 ? major : minor,
      );
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

class CornerFrame extends StatelessWidget {
  const CornerFrame({
    super.key,
    required this.child,
    this.color = Palette.amber,
    this.length = 18,
    this.thickness = 2,
    this.inset = -6,
  });

  final Widget child;
  final Color color;
  final double length;
  final double thickness;
  final double inset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        child,
        Positioned(
          left: inset,
          top: inset,
          right: inset,
          bottom: inset,
          child: IgnorePointer(
            child: CustomPaint(
              painter: _CornerPainter(
                color: color,
                length: length,
                thickness: thickness,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({
    required this.color,
    required this.length,
    required this.thickness,
  });

  final Color color;
  final double length;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(Offset.zero, Offset(length, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, length), paint);

    canvas.drawLine(
        Offset(size.width - length, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);

    canvas.drawLine(
        Offset(0, size.height - length), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);

    canvas.drawLine(Offset(size.width - length, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - length),
        Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.length != length ||
      oldDelegate.thickness != thickness;
}

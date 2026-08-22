import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class GlitchWordmark extends StatelessWidget {
  const GlitchWordmark({
    super.key,
    required this.text,
    required this.progress,
    required this.accentFrom,
    this.fontSize = 54,
  });

  final String text;
  final double progress;
  final int accentFrom;
  final double fontSize;

  static const String _glyphs =
      r'#$%&*+/<>?@=~^ABCDEFGHJKLMNPQRSTUVWXYZ0123456789';

  static const double _start = 0.08;
  static const double _span = 0.52;

  double _charProgress(int index) {
    final double per = _span / text.length;
    final double begin = _start + index * per * 0.72;
    final double end = begin + per * 1.7;
    return ((progress - begin) / (end - begin)).clamp(0.0, 1.0);
  }

  String _glyphFor(int index, double charProgress) {
    if (charProgress >= 1) return text[index];
    final int tick = (progress * 17).floor();
    return _glyphs[(tick * 5 + index * 11) % _glyphs.length];
  }

  double get _aberration {
    final double settle = ((progress - 0.30) / 0.32).clamp(0.0, 1.0);
    final double kick = math.sin(progress * math.pi * 3).abs();
    return (1 - settle) * 7 * (0.45 + 0.55 * kick);
  }

  TextStyle _styleFor(int index, double charProgress, Color color) {
    final bool locked = charProgress >= 1;
    final bool accent = index >= accentFrom;

    return TextStyle(
      fontFamily: AppTheme.monoFallback.first,
      fontFamilyFallback: AppTheme.monoFallback,
      fontSize: fontSize,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: 2,
      color: color,
      shadows: locked && color != Colors.transparent
          ? <Shadow>[
              Shadow(
                color: (accent ? Palette.amber : Palette.white)
                    .withValues(alpha: 0.55),
                blurRadius: 18,
              ),
            ]
          : null,
    );
  }

  Widget _row(Color? override, {double dx = 0, double alpha = 1}) {
    return Transform.translate(
      offset: Offset(dx, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < text.length; i++)
            Builder(
              builder: (BuildContext context) {
                final double cp = _charProgress(i);
                if (cp <= 0) {
                  return Opacity(
                    opacity: 0,
                    child: Text(text[i], style: _styleFor(i, 0, Palette.white)),
                  );
                }

                final bool accent = i >= accentFrom;
                final Color base = cp >= 1
                    ? (accent ? Palette.amber : Palette.white)
                    : Palette.grey;

                return Opacity(
                  opacity: alpha,
                  child: Text(
                    _glyphFor(i, cp),
                    style: _styleFor(i, cp, override ?? base),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double dx = _aberration;

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (dx > 0.3) _row(Palette.grey, dx: -dx, alpha: 0.5),
        if (dx > 0.3) _row(Palette.amber, dx: dx, alpha: 0.6),
        _row(null),
      ],
    );
  }
}

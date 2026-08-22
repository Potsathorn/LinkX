import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/glitch_wordmark.dart';
import 'widgets/splash_effects.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  static const Duration duration = Duration(milliseconds: 1000);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashView.duration,
  );

  bool _left = false;

  @override
  void initState() {
    super.initState();
    _controller.forward().whenCompleteOrCancel(_enter);
  }

  void _enter() {
    if (_left || !mounted) return;
    _left = true;
    context.go(AppRoute.catalogue.path);
  }

  void _skip() {
    if (_controller.isAnimating) _controller.stop();
    _enter();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _window(double t, double begin, double end, {Curve? curve}) {
    final double raw = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve == null ? raw : curve.transform(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, _) {
            final double t = _controller.value;
            final double exit = _window(t, 0.86, 1.0, curve: Curves.easeIn);

            return Opacity(
              opacity: 1 - exit,
              child: Transform.scale(
                scale: 1 + exit * 0.06,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CustomPaint(
                      painter: ScanSweepPainter(
                        progress: _window(t, 0.0, 0.30),
                        color: Palette.amber,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _Mark(t: t, window: _window),
                          const SizedBox(height: 34),
                          SizedBox(
                            width: 168,
                            height: 14,
                            child: CustomPaint(
                              painter: TracePainter(
                                progress: _window(t, 0.52, 0.86,
                                    curve: Curves.easeOutCubic),
                                color: Palette.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 40,
                      right: 40,
                      bottom: 64,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(
                            height: 4,
                            child: CustomPaint(
                              painter: ProgressLinePainter(
                                progress: _window(t, 0.10, 0.95),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Opacity(
                            opacity: _window(t, 0.20, 0.45),
                            child: Text(
                              'DEEPLINK TESTER',
                              style: AppTheme.hudLabel(
                                color: Palette.greyMuted,
                                size: 9.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.t, required this.window});

  final double t;
  final double Function(double, double, double, {Curve? curve}) window;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 24),
              child: GlitchWordmark(
                text: 'LinkX',
                progress: 0,
                accentFrom: 4,
                fontSize: 58,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
              child: GlitchWordmark(
                text: 'LinkX',
                progress: t,
                accentFrom: 4,
                fontSize: 58,
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: ReticlePainter(
                  progress: window(t, 0.44, 0.78, curve: Curves.easeOutCubic),
                  color: Palette.amber,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

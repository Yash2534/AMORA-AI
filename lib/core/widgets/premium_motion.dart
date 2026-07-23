import 'package:flutter/material.dart';

class AmoraMotion {
  const AmoraMotion._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration selection = Duration(milliseconds: 200);
  static const Duration standard = selection;
  static const Duration page = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration largeReveal = Duration(milliseconds: 380);
  static const Duration emphasized = largeReveal;
  static const Duration skeleton = Duration(milliseconds: 900);
  static const Curve curve = Curves.easeOutCubic;
  static const Curve entranceCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const double pressScale = .98;
}

class AmoraPageTransitionsBuilder extends PageTransitionsBuilder {
  const AmoraPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.settings.name == Navigator.defaultRouteName) return child;
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: AmoraMotion.curve,
      reverseCurve: AmoraMotion.curve,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.025, 0.015),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class FadeUp extends StatelessWidget {
  const FadeUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AmoraMotion.standard,
    this.offset = 12,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: AmoraMotion.entranceCurve,
      builder: (context, value, child) {
        final delayedValue = delay == Duration.zero
            ? value
            : ((value * (duration + delay).inMilliseconds -
                          delay.inMilliseconds) /
                      duration.inMilliseconds)
                  .clamp(0.0, 1.0);
        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: Offset(0, (1 - delayedValue) * offset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = AmoraMotion.pressScale,
  });

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: widget.enabled
          ? () => setState(() => _pressed = false)
          : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: AmoraMotion.fast,
        curve: AmoraMotion.curve,
        child: widget.child,
      ),
    );
  }
}

import 'dart:async';

import 'package:amora_ai/core/branding/amora_brand_assets.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmoraSplashScreen extends StatefulWidget {
  const AmoraSplashScreen({super.key, required this.resolveInitialRoute});

  static const routeName = '/splash';

  final FutureOr<String> Function() resolveInitialRoute;

  @override
  State<AmoraSplashScreen> createState() => _AmoraSplashScreenState();
}

class _AmoraSplashScreenState extends State<AmoraSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _exitController;
  late final Future<String> _initialRoute;

  bool _started = false;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initialRoute = Future<String>.sync(widget.resolveInitialRoute);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_runSplash());
  }

  Future<void> _runSplash() async {
    unawaited(precacheImage(const AssetImage(AmoraBrandAssets.icon), context));
    unawaited(
      precacheImage(const AssetImage(AmoraBrandAssets.wordmark), context),
    );
    unawaited(
      precacheImage(const AssetImage(AmoraBrandAssets.tagline), context),
    );

    await _entranceController.forward();
    final destination = await _initialRoute;
    if (!mounted) return;

    await _exitController.forward();
    if (!mounted || _didNavigate) return;
    _didNavigate = true;
    Navigator.of(context).pushReplacementNamed<void, void>(destination);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final reduceMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.splashBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: AppColors.splashBackground,
      ),
      child: Scaffold(
        backgroundColor: AppColors.splashBackground,
        body: AnimatedBuilder(
          animation: Listenable.merge([_entranceController, _exitController]),
          builder: (context, _) {
            final entrance = _entranceController.value;
            final exitOpacity =
                1 - Curves.easeInCubic.transform(_exitController.value);

            return Opacity(
              opacity: exitOpacity,
              child: _SplashCanvas(
                entrance: entrance,
                reduceMotion: reduceMotion,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SplashCanvas extends StatelessWidget {
  const _SplashCanvas({required this.entrance, required this.reduceMotion});

  final double entrance;
  final bool reduceMotion;

  double _interval(double begin, double end, Curve curve) {
    return CurvedAnimation(
      parent: AlwaysStoppedAnimation<double>(entrance),
      curve: Interval(begin, end, curve: curve),
    ).value;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundReveal = _interval(0, 0.18, Curves.easeOutCubic);
    final iconReveal = _interval(0.12, 0.52, Curves.easeOutQuart);
    final wordmarkReveal = _interval(0.35, 0.68, Curves.easeOutCubic);
    final taglineReveal = _interval(0.55, 0.83, Curves.easeOutCubic);
    final contentReveal = _interval(0.08, 0.50, Curves.easeOutCubic);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.splashBackground,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [AppColors.background, AppColors.surface],
          stops: [0, .72 + (.28 * backgroundReveal)],
        ),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final availableWidth = constraints.maxWidth;
            final desiredWidth = availableWidth * (isLandscape ? 0.42 : 0.76);
            final compositionWidth = desiredWidth.clamp(
              224.0,
              isLandscape ? 360.0 : 420.0,
            );
            final iconWidth = (compositionWidth * 0.52).clamp(116.0, 210.0);
            final opticalLift = constraints.maxHeight * -0.028;

            final composition = Semantics(
              label: 'AMORAA. Love, powered by AI',
              image: true,
              child: ExcludeSemantics(
                child: SizedBox(
                  width: compositionWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: reduceMotion ? contentReveal : iconReveal,
                        child: Transform.translate(
                          offset: reduceMotion
                              ? Offset.zero
                              : Offset(0, 12 * (1 - iconReveal)),
                          child: Transform.scale(
                            scale: reduceMotion
                                ? 1
                                : 0.92 + (0.08 * iconReveal),
                            child: Image.asset(
                              AmoraBrandAssets.icon,
                              width: iconWidth,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isLandscape ? 16 : 24),
                      Opacity(
                        opacity: reduceMotion ? contentReveal : wordmarkReveal,
                        child: Transform.translate(
                          offset: reduceMotion
                              ? Offset.zero
                              : Offset(0, 9 * (1 - wordmarkReveal)),
                          child: Image.asset(
                            AmoraBrandAssets.wordmark,
                            width: compositionWidth,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      SizedBox(height: isLandscape ? 10 : 14),
                      Opacity(
                        opacity: reduceMotion ? contentReveal : taglineReveal,
                        child: Transform.translate(
                          offset: reduceMotion
                              ? Offset.zero
                              : Offset(0, 7 * (1 - taglineReveal)),
                          child: Image.asset(
                            AmoraBrandAssets.tagline,
                            width: compositionWidth * 0.88,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            return Center(
              child: Transform.translate(
                offset: Offset(0, opticalLift),
                child: composition,
              ),
            );
          },
        ),
      ),
    );
  }
}

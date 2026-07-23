import 'dart:async';
import 'dart:math' as math;

import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/auth/presentation/amora_auth_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _pulse;
  late final AnimationController _particles;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat(reverse: true);
    _particles = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    _timer = Timer(const Duration(milliseconds: 2450), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, animation, _) => const AmoraAuthScreen(),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: .985, end: 1).animate(animation),
              child: child,
            ),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    _pulse.dispose();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _pulse, _particles]),
        builder: (context, _) {
          final intro = Curves.easeOutCubic.transform(_intro.value);
          return DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HeartParticlePainter(_particles.value),
                  ),
                ),
                SafeArea(
                  child: ResponsiveMobileFrame(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxHeight < 640;
                        final inset = compact
                            ? AmoraSpacing.space12
                            : AmoraSpacing.space24;
                        return SingleChildScrollView(
                          padding: EdgeInsets.all(inset),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - (inset * 2),
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: _VersionPill(progress: intro),
                                  ),
                                  const Spacer(),
                                  Transform.translate(
                                    offset: Offset(0, 18 * (1 - intro)),
                                    child: Opacity(
                                      opacity: intro,
                                      child: _AnimatedLogo(
                                        pulse: _pulse.value,
                                        compact: compact,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: compact
                                        ? AmoraSpacing.space12
                                        : AmoraSpacing.space24,
                                  ),
                                  Opacity(
                                    opacity: intro,
                                    child: Text(
                                      'Designed for intentional Indian love stories',
                                      textAlign: TextAlign.center,
                                      style: AmoraTextStyles.titleMedium
                                          .copyWith(color: AppColors.surface),
                                    ),
                                  ),
                                  const SizedBox(height: AmoraSpacing.space8),
                                  Opacity(
                                    opacity: intro,
                                    child: Text(
                                      'Premium AI-Powered matching, verified people, safer first dates.',
                                      textAlign: TextAlign.center,
                                      style: AmoraTextStyles.bodyMedium
                                          .copyWith(
                                            color: AppColors.surface.withValues(
                                              alpha: .84,
                                            ),
                                          ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: compact
                                        ? AmoraSpacing.space16
                                        : AmoraSpacing.space32,
                                  ),
                                  _LoadingShimmer(progress: _particles.value),
                                  const Spacer(),
                                  Text(
                                    'v1.0.0',
                                    style: AmoraTextStyles.labelSmall.copyWith(
                                      color: AppColors.surface.withValues(
                                        alpha: .72,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AmoraSpacing.space8),
                                  Text(
                                    'Preparing your compatibility engine',
                                    textAlign: TextAlign.center,
                                    style: AmoraTextStyles.bodySmall.copyWith(
                                      color: AppColors.surface.withValues(
                                        alpha: .72,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedLogo extends StatelessWidget {
  const _AnimatedLogo({required this.pulse, required this.compact});

  final double pulse;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scale = .96 + (.08 * pulse);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: compact ? 132 : 178,
          height: compact ? 132 : 178,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Transform.scale(
                  scale: 1 + (pulse * (.24 + i * .13)),
                  child: Container(
                    width: (compact ? 88 : 122) + i * (compact ? 12 : 18),
                    height: (compact ? 88 : 122) + i * (compact ? 12 : 18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface),
                    ),
                  ),
                ),
              Container(
                width: compact ? 100 : 132,
                height: compact ? 100 : 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  boxShadow: AmoraShadows.floating,
                ),
              ),
              Transform.scale(
                scale: scale,
                child: Hero(
                  tag: 'amora-logo',
                  child: ClipOval(
                    child: Image.asset(
                      AppImages.logo,
                      width: compact ? 88 : 116,
                      height: compact ? 88 : 116,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _FallbackLogo(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? AmoraSpacing.space8 : AmoraSpacing.space12),
        Text.rich(
          TextSpan(
            text: 'AMORA ',
            children: [
              TextSpan(
                text: 'AI',
                style:
                    (compact
                            ? AmoraTextStyles.headlineLarge
                            : AmoraTextStyles.displaySmall)
                        .copyWith(color: AppColors.tertiary),
              ),
            ],
          ),
          style:
              (compact
                      ? AmoraTextStyles.headlineLarge
                      : AmoraTextStyles.displaySmall)
                  .copyWith(color: AppColors.surface),
        ),
      ],
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.deepWine,
      child: Center(
        child: Icon(Icons.favorite_rounded, color: AppColors.surface, size: 54),
      ),
    );
  }
}

class _VersionPill extends StatelessWidget {
  const _VersionPill({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AmoraSpacing.space12,
          vertical: AmoraSpacing.space8,
        ),
        decoration: BoxDecoration(
          color: AppColors.text,
          borderRadius: AmoraRadius.pillBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_rounded,
              color: AppColors.premiumGold,
              size: 16,
            ),
            SizedBox(width: AmoraSpacing.space8),
            Flexible(
              child: Text(
                'Version check 1.0.0',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.labelMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AmoraRadius.pillBorder,
      ),
      clipBehavior: Clip.antiAlias,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: .38 + (progress * .54),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AmoraRadius.pillBorder,
            gradient: const LinearGradient(
              colors: [
                AppColors.tertiary,
                AppColors.surface,
                AppColors.premiumGold,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeartParticlePainter extends CustomPainter {
  _HeartParticlePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const seeds = [0.11, 0.24, 0.37, 0.52, 0.67, 0.79, 0.91, 0.46];
    for (var i = 0; i < seeds.length; i++) {
      final lane = seeds[i];
      final drift = math.sin((progress * math.pi * 2) + i) * 18;
      final y = size.height * ((lane + progress + i * .07) % 1);
      final x = (size.width * ((lane * 1.73) % 1)) + drift;
      final alpha = (.08 + (i % 3) * .035).clamp(0.0, 1.0);
      paint.color = AppColors.surface.withValues(alpha: alpha);
      _drawHeart(canvas, Offset(x, y), 7 + (i % 4) * 2.2, paint);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy + size * .45)
      ..cubicTo(
        center.dx - size * 1.35,
        center.dy - size * .25,
        center.dx - size * .72,
        center.dy - size * 1.18,
        center.dx,
        center.dy - size * .52,
      )
      ..cubicTo(
        center.dx + size * .72,
        center.dy - size * 1.18,
        center.dx + size * 1.35,
        center.dy - size * .25,
        center.dx,
        center.dy + size * .45,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

import 'dart:math' as math;

import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/profile_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/chat/data/chat_repository.dart';
import 'package:amora_ai/features/match/presentation/why_we_matched_screen.dart';
import 'package:flutter/material.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  static const routeName = '/match';

  @override
  Widget build(BuildContext context) {
    final argument = ModalRoute.of(context)?.settings.arguments;
    final profile = argument is AmoraProfileCardData ? argument : null;
    final name = profile?.name ?? 'Kavya Shah';
    final image = profile?.imageUrl ?? AppImages.profileKavya;
    final fallback = profile?.fallbackAsset ?? AppImages.femaleProfileFallback;
    final initials = profile?.initials ?? AppImages.initialsForName(name);
    final score = profile?.score ?? 92;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AmoraSpacing.space24,
                AmoraSpacing.space20,
                AmoraSpacing.space24,
                AmoraSpacing.space32 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton.filledTonal(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                        Text(
                          'Compatibility',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AmoraTextStyles.titleLarge.copyWith(
                            color: AppColors.deepWine,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AmoraSpacing.space16),
                  _CompatibilityHero(
                    name: name,
                    image: image,
                    fallback: fallback,
                    initials: initials,
                    score: score,
                  ),
                  const SizedBox(height: AmoraSpacing.space16),
                  _ScoreGrid(score: score),
                  const SizedBox(height: AmoraSpacing.space16),
                  const _AiSummary(),
                  const SizedBox(height: AmoraSpacing.space16),
                  _MetricList(
                    metrics: [
                      _Metric('Relationship Potential', 94),
                      _Metric('Personality Match', 91),
                      _Metric('Communication Match', 88),
                      _Metric('Lifestyle Match', 86),
                      _Metric('Love Language', 90),
                      _Metric('Values Alignment', 93),
                      _Metric('Trust Level', 89),
                      _Metric('Dating Intentions', 96),
                    ],
                  ),
                  const SizedBox(height: AmoraSpacing.space20),
                  AppPrimaryButton(
                    label: 'Open Detailed Report',
                    icon: Icons.insights_rounded,
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(WhyWeMatchedScreen.routeName),
                  ),
                  const SizedBox(height: AmoraSpacing.space12),
                  AppPrimaryButton(
                    label: 'Message Now',
                    icon: Icons.chat_bubble_rounded,
                    variant: AppPrimaryButtonVariant.outlined,
                    onPressed: () async {
                      final participant = ImageRepository.profileByName(name);
                      final conversationId = await ChatRepository.instance
                          .createConversationForProfile(participant);
                      if (!context.mounted) return;
                      Navigator.of(context).pushNamed(
                        ChatDetailScreen.routeName,
                        arguments: ChatDetailArgs(
                          conversationId: conversationId,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompatibilityHero extends StatelessWidget {
  const _CompatibilityHero({
    required this.name,
    required this.image,
    required this.fallback,
    required this.initials,
    required this.score,
  });

  final String name;
  final String image;
  final String fallback;
  final String initials;
  final int score;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      padding: const EdgeInsets.all(AmoraSpacing.space20),
      child: Column(
        children: [
          SizedBox(
            height: 196,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: AmoraSpacing.space20,
                  child: _MatchAvatar(
                    image: AppImages.profileYash,
                    fallback: AppImages.maleProfileFallback,
                    initials: 'YA',
                  ),
                ),
                Positioned(
                  right: AmoraSpacing.space20,
                  child: _MatchAvatar(
                    image: image,
                    fallback: fallback,
                    initials: initials,
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: score / 100),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return SizedBox(
                      width: 122,
                      height: 122,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: value,
                            strokeWidth: 10,
                            color: AppColors.primaryRose,
                            backgroundColor: AppColors.lavenderBackground,
                          ),
                          Center(
                            child: Text(
                              '${(value * 100).round()}%',
                              style: AmoraTextStyles.headlineLarge.copyWith(
                                color: AppColors.deepWine,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Text(
            '$score% Excellent Match',
            textAlign: TextAlign.center,
            style: AmoraTextStyles.headlineMedium,
          ),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            'You and ${name.split(' ').first} both show strong long-term intent, warm communication, and compatible lifestyle signals.',
            textAlign: TextAlign.center,
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreGrid extends StatelessWidget {
  const _ScoreGrid({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 30,
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const metrics = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TinyMetric('Shared Interests', 'Travel, food, music'),
              SizedBox(height: 12),
              _TinyMetric('Future Goals', 'Long-term focused'),
              SizedBox(height: 12),
              _TinyMetric('Trust Level', 'Verified-ready profile'),
            ],
          );
          final radar = SizedBox(
            width: 132,
            height: 132,
            child: CustomPaint(
              painter: _RadarPainter(values: const [.94, .91, .88, .86, .9]),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: radar),
              const SizedBox(height: 18),
              metrics,
            ],
          );
        },
      ),
    );
  }
}

class _AiSummary extends StatelessWidget {
  const _AiSummary();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      color: AppColors.deepWine,
      padding: const EdgeInsets.all(AmoraSpacing.space20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.premiumGold),
          const SizedBox(width: AmoraSpacing.space12),
          Expanded(
            child: Text(
              'Because you both enjoy travel, meaningful conversations, family values, and long-term relationships.',
              style: AmoraTextStyles.bodyLarge.copyWith(
                color: AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricList extends StatelessWidget {
  const _MetricList({required this.metrics});

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      padding: const EdgeInsets.all(AmoraSpacing.space20),
      child: Column(
        children: [
          for (final metric in metrics) ...[
            _MetricRow(metric: metric),
            if (metric != metrics.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                metric.label,
                style: AmoraTextStyles.bodyLarge.copyWith(
                  color: AppColors.deepWine,
                ),
              ),
            ),
            Text(
              '${metric.value}%',
              style: AmoraTextStyles.labelLarge.copyWith(
                color: AppColors.primaryPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: AmoraRadius.pillBorder,
          child: LinearProgressIndicator(
            value: metric.value / 100,
            minHeight: 7,
            color: AppColors.primaryPurple,
            backgroundColor: AppColors.lavenderBackground,
          ),
        ),
      ],
    );
  }
}

class _TinyMetric extends StatelessWidget {
  const _TinyMetric(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AmoraTextStyles.bodyLarge.copyWith(color: AppColors.deepWine),
        ),
        const SizedBox(height: AmoraSpacing.space4),
        Text(
          value,
          style: AmoraTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
        ),
      ],
    );
  }
}

class _MatchAvatar extends StatelessWidget {
  const _MatchAvatar({
    required this.image,
    required this.fallback,
    required this.initials,
  });

  final String image;
  final String fallback;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 148,
      padding: const EdgeInsets.all(AmoraSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AmoraRadius.card,
        boxShadow: AmoraShadows.level2,
      ),
      child: AmoraProfileImage(
        imageUrl: image,
        assetPath: fallback,
        initials: initials,
        borderRadius: AmoraRadius.card,
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value);

  final String label;
  final int value;
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final gridPaint = Paint()
      ..color = AppColors.borderGray
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fillPaint = Paint()
      ..color = AppColors.primaryPurple.withValues(alpha: .18)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = AppColors.primaryPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    for (final scale in const [.33, .66, 1.0]) {
      canvas.drawPath(_polygon(center, radius * scale, null), gridPaint);
    }
    canvas.drawPath(_polygon(center, radius, values), fillPaint);
    canvas.drawPath(_polygon(center, radius, values), linePaint);
  }

  Path _polygon(Offset center, double radius, List<double>? weightedValues) {
    final path = Path();
    final count = values.length;
    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (math.pi * 2 * i / count);
      final weight = weightedValues == null ? 1 : weightedValues[i];
      final point = Offset(
        center.dx + math.cos(angle) * radius * weight,
        center.dy + math.sin(angle) * radius * weight,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

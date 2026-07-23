import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:flutter/material.dart';

class AmoraLoading extends StatelessWidget {
  const AmoraLoading({super.key, this.label, this.compact = false});

  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label ?? 'Loading',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: compact ? AmoraSpacing.space24 : AmoraSpacing.space32,
              child: const CircularProgressIndicator(
                strokeWidth: AmoraSpacing.space4,
                strokeCap: StrokeCap.round,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: AmoraSpacing.space16),
              Text(
                label!,
                textAlign: TextAlign.center,
                style: AmoraTextStyles.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AmoraLinearLoading extends StatelessWidget {
  const AmoraLinearLoading({super.key, this.value, this.label});

  final double? value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label ?? 'Loading',
      value: value == null ? null : '${(value! * 100).round()} percent',
      child: LinearProgressIndicator(value: value),
    );
  }
}

class AmoraSkeleton extends StatefulWidget {
  const AmoraSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = AmoraRadius.large,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<AmoraSkeleton> createState() => _AmoraSkeletonState();
}

class _AmoraSkeletonState extends State<AmoraSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AmoraMotion.skeleton,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.surfaceContainer,
              AppColors.surfaceContainerHighest,
              _controller.value,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

class AmoraCardSkeleton extends StatelessWidget {
  const AmoraCardSkeleton({super.key, this.height = 160});
  final double height;

  @override
  Widget build(BuildContext context) => AmoraSkeleton(
    width: double.infinity,
    height: height,
    radius: AmoraRadius.extraLarge,
  );
}

class AmoraProfileSkeleton extends StatelessWidget {
  const AmoraProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        AmoraSkeleton(width: 64, height: 64, radius: AmoraRadius.full),
        SizedBox(width: AmoraSpacing.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmoraSkeleton(width: 160, height: 16),
              SizedBox(height: AmoraSpacing.space8),
              AmoraSkeleton(width: 112, height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

class AmoraListSkeleton extends StatelessWidget {
  const AmoraListSkeleton({super.key, this.itemCount = 4});
  final int itemCount;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < itemCount; index++) ...[
        const AmoraProfileSkeleton(),
        if (index != itemCount - 1)
          const SizedBox(height: AmoraSpacing.space16),
      ],
    ],
  );
}

class AmoraGridSkeleton extends StatelessWidget {
  const AmoraGridSkeleton({super.key, this.itemCount = 6});
  final int itemCount;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: itemCount,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: AmoraSpacing.space12,
      mainAxisSpacing: AmoraSpacing.space12,
    ),
    itemBuilder: (_, _) =>
        const AmoraSkeleton(height: 160, radius: AmoraRadius.extraLarge),
  );
}

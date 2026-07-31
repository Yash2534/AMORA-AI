import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_gradients.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:flutter/material.dart';

class ImageFallback extends StatelessWidget {
  const ImageFallback({
    super.key,
    required this.initials,
    this.width,
    this.height,
    this.showRetry = false,
  });

  final String initials;
  final double? width;
  final double? height;
  final bool showRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AmoraGradients.primaryDiagonal,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(AmoraSpacing.x3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    initials,
                    style: AmoraTextStyles.headlineMedium.copyWith(
                      color: AppColors.surface,
                    ),
                  ),
                  if (showRetry) ...[
                    const SizedBox(height: AmoraSpacing.x2),
                    const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.surface,
                      size: AmoraIconSizes.medium,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ImageSkeleton extends StatefulWidget {
  const ImageSkeleton({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<ImageSkeleton> createState() => _ImageSkeletonState();
}

class _ImageSkeletonState extends State<ImageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AmoraMotion.skeleton,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final start = -1.0 + (_controller.value * 2);
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(start, -1),
                end: Alignment(start + 1, 1),
                colors: const [AppColors.background, AppColors.surface],
              ),
            ),
          ),
        );
      },
    );
  }
}

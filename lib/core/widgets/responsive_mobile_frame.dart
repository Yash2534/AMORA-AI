import 'package:flutter/material.dart';

class ResponsiveMobileFrame extends StatelessWidget {
  const ResponsiveMobileFrame({
    super.key,
    required this.child,
    this.maxWidth = 460,
    this.background,
  });

  final Widget child;
  final double maxWidth;
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Preserve the available width on phones and center a readable mobile
        // column on larger canvases.  Keeping the lower clamp relative to the
        // requested max width also makes custom, narrower frames safe.
        final effectiveMaxWidth = maxWidth
            .clamp(0.0, constraints.maxWidth)
            .toDouble();
        final width = constraints.maxWidth >= 600
            ? effectiveMaxWidth
            : constraints.maxWidth;

        return Stack(
          fit: StackFit.expand,
          children: [
            ?background,
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints.tightFor(width: width),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

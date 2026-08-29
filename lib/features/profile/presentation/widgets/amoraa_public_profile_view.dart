import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

enum PublicProfileViewMode { otherUser, preview }

typedef AmoraaPublicProfileGalleryBuilder =
    Widget Function(BuildContext context, double height, bool desktop);

class AmoraaPublicProfileView extends StatelessWidget {
  const AmoraaPublicProfileView({
    super.key,
    required this.mode,
    required this.galleryBuilder,
    required this.story,
    this.interactionBar,
    this.interactionOverlay,
    this.scrollKey,
  });

  final PublicProfileViewMode mode;
  final AmoraaPublicProfileGalleryBuilder galleryBuilder;
  final Widget story;
  final Widget? interactionBar;
  final Widget? interactionOverlay;
  final Key? scrollKey;

  bool get _showsInteractions =>
      mode == PublicProfileViewMode.otherUser && interactionBar != null;

  @override
  Widget build(BuildContext context) {
    return ResponsiveMobileFrame(
      key: ValueKey('amoraa-public-profile-view-${mode.name}'),
      maxWidth: 1080,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 760;
          final horizontalPadding = desktop
              ? AmoraSpacing.space24
              : constraints.maxWidth < 360
              ? AmoraSpacing.space16
              : AmoraSpacing.space20;
          final galleryHeight = desktop
              ? (constraints.maxHeight - 48).clamp(560.0, 760.0)
              : (constraints.maxHeight * .62).clamp(420.0, 620.0);
          final gallery = galleryBuilder(context, galleryHeight, desktop);
          final content = desktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 10, child: gallery),
                    const SizedBox(width: AmoraSpacing.space24),
                    Expanded(flex: 11, child: story),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    gallery,
                    const SizedBox(height: AmoraSpacing.space20),
                    story,
                  ],
                );
          final scrollView = SingleChildScrollView(
            key: scrollKey,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              desktop ? AmoraSpacing.space24 : 0,
              horizontalPadding,
              _showsInteractions ? AmoraSpacing.space16 : AmoraSpacing.space40,
            ),
            child: content,
          );
          final page = _showsInteractions
              ? Column(
                  children: [
                    Expanded(child: scrollView),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        AmoraSpacing.space8,
                        horizontalPadding,
                        AmoraSpacing.space8,
                      ),
                      child: interactionBar!,
                    ),
                  ],
                )
              : scrollView;
          return Stack(
            fit: StackFit.expand,
            children: [
              page,
              if (mode == PublicProfileViewMode.otherUser &&
                  interactionOverlay != null)
                Positioned.fill(child: interactionOverlay!),
            ],
          );
        },
      ),
    );
  }
}

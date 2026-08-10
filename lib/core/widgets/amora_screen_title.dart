import 'package:amora_ai/core/theme/amora_header_tokens.dart';
import 'package:flutter/material.dart';

/// The shared title block used by headers that retain an existing subtitle.
class AmoraScreenTitle extends StatelessWidget {
  const AmoraScreenTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.titleMaxLines = 1,
  });

  final String title;
  final String? subtitle;
  final int titleMaxLines;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: titleMaxLines,
            overflow: TextOverflow.ellipsis,
            style: AmoraHeaderTokens.titleStyle,
          ),
          if (subtitle case final subtitle?) ...[
            const SizedBox(height: AmoraHeaderTokens.titleSubtitleGap),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmoraHeaderTokens.subtitleStyle,
            ),
          ],
        ],
      ),
    );
  }
}

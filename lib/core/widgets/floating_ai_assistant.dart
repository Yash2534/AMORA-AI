import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/features/ai_coach/presentation/ai_coach_screen.dart';
import 'package:flutter/material.dart';

class FloatingAiAssistant extends StatelessWidget {
  const FloatingAiAssistant({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'AMORAA assistant',
      child: FloatingActionButton(
        heroTag: 'amora-ai-assistant',
        onPressed: () => _openAssistant(context),
        child: const Icon(Icons.auto_awesome_rounded),
      ),
    );
  }

  void _openAssistant(BuildContext context) {
    if (AmoraSession.isGuest) {
      AmoraSession.requireAuth(
        context: context,
        onAuthenticated: () => _openAssistant(context),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: .75,
          minChildSize: .45,
          maxChildSize: .95,
          builder: (context, scrollController) {
            return Material(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView(
                controller: scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  left: AmoraSpacing.space20,
                  right: AmoraSpacing.space20,
                  top: AmoraSpacing.space16,
                  bottom:
                      MediaQuery.viewInsetsOf(context).bottom +
                      MediaQuery.viewPaddingOf(context).bottom +
                      AmoraSpacing.space24,
                ),
                children: [
                  Center(
                    child: Container(
                      width: AmoraSpacing.space32,
                      height: AmoraSpacing.space4,
                      decoration: BoxDecoration(
                        color: AppColors.borderGray,
                        borderRadius: AmoraRadius.pillBorder,
                      ),
                    ),
                  ),
                  const SizedBox(height: AmoraSpacing.space20),
                  const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.lavenderBackground,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      SizedBox(width: AmoraSpacing.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AMORAA Assistant',
                              style: AmoraTextStyles.titleLarge,
                            ),
                            SizedBox(height: AmoraSpacing.space4),
                            Text(
                              'Fast help for profile, chat, date planning, and confidence.',
                              style: AmoraTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AmoraSpacing.space16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final tileWidth = (constraints.maxWidth - 8) / 2;
                      return Wrap(
                        spacing: AmoraSpacing.space8,
                        runSpacing: AmoraSpacing.space8,
                        children: [
                          _AssistantAction(
                            width: tileWidth,
                            icon: Icons.person_search_rounded,
                            label: 'Improve My Profile',
                            onTap: () => _openCoach(sheetContext, context),
                          ),
                          _AssistantAction(
                            width: tileWidth,
                            icon: Icons.reply_rounded,
                            label: 'Help Me Reply',
                            onTap: () => _openCoach(sheetContext, context),
                          ),
                          _AssistantAction(
                            width: tileWidth,
                            icon: Icons.sentiment_very_satisfied_rounded,
                            label: 'Funny Reply',
                            onTap: () => _openCoach(sheetContext, context),
                          ),
                          _AssistantAction(
                            width: tileWidth,
                            icon: Icons.favorite_rounded,
                            label: 'Romantic Reply',
                            onTap: () => _openCoach(sheetContext, context),
                          ),
                          _AssistantAction(
                            width: tileWidth,
                            icon: Icons.local_fire_department_rounded,
                            label: 'Flirty Reply',
                            onTap: () => _openCoach(sheetContext, context),
                          ),
                          _AssistantAction(
                            width: tileWidth,
                            icon: Icons.bolt_rounded,
                            label: 'Confident Reply',
                            onTap: () => _openCoach(sheetContext, context),
                          ),
                          _AssistantAction(
                            width: tileWidth,
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Conversation Rescue',
                            onTap: () => _openCoach(sheetContext, context),
                          ),
                          _AssistantAction(
                            width: tileWidth,
                            icon: Icons.analytics_rounded,
                            label: 'Conversation Analysis',
                            onTap: () => _openCoach(sheetContext, context),
                          ),
                          _AssistantAction(
                            width: tileWidth,
                            icon: Icons.event_available_rounded,
                            label: 'Date Preparation',
                            onTap: () => _openCoach(sheetContext, context),
                          ),
                          _AssistantAction(
                            width: tileWidth,
                            icon: Icons.self_improvement_rounded,
                            label: 'Confidence Boost',
                            onTap: () => _openCoach(sheetContext, context),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AmoraSpacing.space16),
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void _openCoach(BuildContext sheetContext, BuildContext context) {
    Navigator.of(sheetContext).pop();
    Navigator.of(context).pushNamed(AiCoachScreen.routeName);
  }
}

class _AssistantAction extends StatelessWidget {
  const _AssistantAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.width,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: AmoraRadius.button,
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: AmoraSpacing.compactCard,
          decoration: BoxDecoration(
            color: AppColors.lightPinkBackground,
            borderRadius: AmoraRadius.button,
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: AmoraSpacing.space8),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

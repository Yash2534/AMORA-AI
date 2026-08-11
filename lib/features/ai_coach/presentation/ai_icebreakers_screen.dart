import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/chat/data/chat_repository.dart';
import 'package:amora_ai/features/monetization/data/monetization_data.dart';
import 'package:amora_ai/features/monetization/presentation/widgets/monetization_widgets.dart';
import 'package:flutter/material.dart';

class AiIcebreakersScreen extends StatefulWidget {
  const AiIcebreakersScreen({super.key});

  static const routeName = '/ai-icebreakers';

  @override
  State<AiIcebreakersScreen> createState() => _AiIcebreakersScreenState();
}

class _AiIcebreakersScreenState extends State<AiIcebreakersScreen> {
  var _tone = icebreakerTones.first;
  late final List<String> _suggestions = List<String>.from(icebreakers);

  @override
  Widget build(BuildContext context) {
    final profile = _IcebreakerProfile.fromArgs(
      ModalRoute.of(context)?.settings.arguments,
    );
    if (profile == null) {
      return Scaffold(
        appBar: AmoraAppBar(
          title: 'AI Icebreakers',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Open AI Icebreakers from an available match.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AmoraAppBar(
        title: 'AI Icebreakers',
        subtitle: 'Send something specific, warm, and respectful.',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: ResponsiveMobileFrame(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AmoraSpacing.space16,
                AmoraSpacing.x5,
                AmoraSpacing.x5,
                110,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MatchMiniCard(profile: profile),
                  const SizedBox(height: AmoraSpacing.x4),
                  const SectionTitle(title: 'Tone'),
                  const SizedBox(height: 12),
                  AmoraaCompactSelect<String>(
                    label: 'Tone',
                    value: _tone,
                    prefixIcon: Icons.tune_rounded,
                    options: [
                      for (final tone in icebreakerTones)
                        AmoraaSelectOption(value: tone, label: tone),
                    ],
                    onChanged: (tone) {
                      if (tone != null) setState(() => _tone = tone);
                    },
                  ),
                  const SizedBox(height: AmoraSpacing.x4),
                  SectionTitle(title: 'Generated icebreakers', subtitle: _tone),
                  const SizedBox(height: 12),
                  for (final suggestion in _suggestions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: IcebreakerCard(
                        text: suggestion,
                        onCustomize: () => _customize(suggestion),
                        onSend: () => _send(suggestion),
                      ),
                    ),
                  const SizedBox(height: 8),
                  AppPrimaryButton(
                    label: 'Generate More',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: _generateMore,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _generateMore() {
    setState(() {
      _suggestions.insert(
        0,
        'Since you both enjoy thoughtful dates, what is one place in Ahmedabad you never get tired of revisiting?',
      );
    });
    showPremiumSnack(context, 'New icebreaker generated');
  }

  void _customize(String text) {
    final controller = TextEditingController(text: text);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customize icebreaker',
                  style: TextStyle(
                    color: AppColors.deepWine,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Write your opener',
                  ),
                ),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: 'Save Custom Text',
                  icon: Icons.check_rounded,
                  onPressed: () {
                    final index = _suggestions.indexOf(text);
                    if (index >= 0) {
                      setState(
                        () => _suggestions[index] = controller.text.trim(),
                      );
                    }
                    Navigator.pop(context);
                    showPremiumSnack(context, 'Icebreaker customized');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _send(String text) async {
    final profile = _IcebreakerProfile.fromArgs(
      ModalRoute.of(context)?.settings.arguments,
    );
    if (profile == null) return;
    try {
      final conversationId = await ChatRepository.instance
          .createConversationForUserId(profile.id);
      if (!mounted) return;
      Navigator.of(context).pushNamed(
        ChatDetailScreen.routeName,
        arguments: ChatDetailArgs(
          conversationId: conversationId,
          prefillText: text,
        ),
      );
    } catch (_) {
      if (mounted) showPremiumSnack(context, 'Could not open this chat.');
    }
  }
}

class _IcebreakerProfile {
  const _IcebreakerProfile({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.initials,
  });

  final String id;
  final String name;
  final String subtitle;
  final String imageUrl;
  final String fallbackAsset;
  final String initials;

  String get firstName => name.split(',').first.split(' ').first;

  static _IcebreakerProfile? fromArgs(Object? args) {
    if (args is Map) {
      final id = args['id']?.toString();
      final name = args['name']?.toString();
      if (id != null &&
          int.tryParse(id) != null &&
          name != null &&
          name.trim().isNotEmpty) {
        return _IcebreakerProfile(
          id: id,
          name: name,
          subtitle:
              args['subtitle']?.toString() ??
              'Thoughtful profile, shared interests',
          imageUrl: args['imageUrl']?.toString() ?? '',
          fallbackAsset: args['fallbackAsset']?.toString() ?? '',
          initials: args['initials']?.toString() ?? 'AM',
        );
      }
    }
    return null;
  }
}

class _MatchMiniCard extends StatelessWidget {
  const _MatchMiniCard({required this.profile});

  final _IcebreakerProfile profile;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        children: [
          PremiumAvatar(
            imageUrl: profile.imageUrl,
            fallbackAsset: profile.fallbackAsset,
            initials: profile.initials,
            radius: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    color: AppColors.deepWine,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  profile.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.premiumGold.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.premiumGold),
            ),
            child: const Text(
              '92%',
              style: TextStyle(
                color: AppColors.deepWine,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

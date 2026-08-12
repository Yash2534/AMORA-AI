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
import 'package:amora_ai/features/monetization/presentation/widgets/monetization_widgets.dart';
import 'package:flutter/material.dart';

class AiIcebreakersScreen extends StatefulWidget {
  const AiIcebreakersScreen({super.key});

  static const routeName = '/ai-icebreakers';

  @override
  State<AiIcebreakersScreen> createState() => _AiIcebreakersScreenState();
}

class _AiIcebreakersScreenState extends State<AiIcebreakersScreen> {
  static const _tones = <String>['Thoughtful', 'Warm', 'Curious', 'Playful'];

  var _tone = _tones.first;
  final List<String> _suggestions = <String>[];
  _IcebreakerProfile? _profile;
  var _nextSeed = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profile != null) return;
    _profile = _IcebreakerProfile.fromArgs(
      ModalRoute.of(context)?.settings.arguments,
    );
    final profile = _profile;
    if (profile != null) {
      _suggestions.addAll(
        List<String>.generate(3, (_) => _nextSuggestion(profile)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      return Scaffold(
        appBar: AmoraAppBar(
          title: 'Conversation Starters',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Open conversation starters from an available match.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AmoraAppBar(
        title: 'Conversation Starters',
        subtitle: 'Created on-device from visible profile details.',
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
                      for (final tone in _tones)
                        AmoraaSelectOption(value: tone, label: tone),
                    ],
                    onChanged: (tone) {
                      if (tone != null) setState(() => _tone = tone);
                    },
                  ),
                  const SizedBox(height: AmoraSpacing.x4),
                  SectionTitle(title: 'On-device suggestions', subtitle: _tone),
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
                    label: 'Create Another',
                    icon: Icons.add_comment_rounded,
                    onPressed: () => _createAnother(profile),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _createAnother(_IcebreakerProfile profile) {
    setState(() {
      _suggestions.insert(0, _nextSuggestion(profile));
    });
    showPremiumSnack(context, 'Created another on-device suggestion');
  }

  String _nextSuggestion(_IcebreakerProfile profile) {
    final seed = _nextSeed++;
    final interest = profile.interests.isEmpty
        ? null
        : profile.interests[seed % profile.interests.length];
    final firstName = profile.firstName;
    final candidates = <String>[
      if (interest != null)
        '$firstName, I noticed you enjoy $interest. What first got you interested in it?',
      '$firstName, what is something small that made your week better?',
      '$firstName, what kind of first conversation feels most natural to you?',
      '$firstName, what is one place you would happily revisit and why?',
    ];
    final base = candidates[seed % candidates.length];
    return switch (_tone) {
      'Warm' => 'Hi $base',
      'Curious' => '$base I would love to hear the story behind it.',
      'Playful' => '$base Bonus points for an unexpected answer.',
      _ => base,
    };
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
                    final customized = controller.text.trim();
                    if (customized.isEmpty) {
                      showPremiumSnack(
                        context,
                        'Write a message before saving it.',
                      );
                      return;
                    }
                    final index = _suggestions.indexOf(text);
                    if (index >= 0) {
                      setState(() => _suggestions[index] = customized);
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
    final profile = _profile;
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
    required this.score,
    required this.interests,
  });

  final String id;
  final String name;
  final String subtitle;
  final String imageUrl;
  final String fallbackAsset;
  final String initials;
  final int score;
  final List<String> interests;

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
          score: (args['score'] as num?)?.round().clamp(0, 100) ?? 0,
          interests: ((args['interests'] as List?) ?? const <dynamic>[])
              .map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty)
              .toList(growable: false),
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
          if (profile.score > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.premiumGold.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.premiumGold),
              ),
              child: Text(
                '${profile.score}%',
                style: const TextStyle(
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

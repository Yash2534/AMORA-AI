import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/amora_bottom_sheet.dart';
import 'package:amora_ai/core/widgets/amora_badge.dart';
import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:amora_ai/core/widgets/premium_editorial_panel.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/chat/presentation/chat_list_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/safety/presentation/blocked_user_success_sheet.dart';
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
import 'package:amora_ai/features/safety/widgets/block_confirmation_dialog.dart';
import 'package:flutter/material.dart';

class ChatDetailSeed {
  const ChatDetailSeed({this.prefillText});

  final String? prefillText;
}

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  static const routeName = '/chat-detail';

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _seedApplied = false;
  bool _readReceipts = true;
  bool _blocked = false;
  DummyProfile get _profile => _chatProfile;
  String get _firstName => _profile.name.split(' ').first;

  final List<ChatMessage> _messages = [
    const ChatMessage(
      text:
          "Your poetry prompt caught my eye. I didn't expect to find another old-city person here.",
      mine: false,
      time: '10:18',
    ),
    const ChatMessage(
      text: 'Then we already have a plan: heritage walk first, coffee after.',
      mine: true,
      time: '10:20',
      read: true,
    ),
    const ChatMessage(
      text: 'That Gujarati thali line made me laugh',
      mine: false,
      time: '10:21',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seedApplied) return;
    _seedApplied = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ChatDetailSeed && args.prefillText?.isNotEmpty == true) {
      _controller.text = args.prefillText!;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: Column(
              children: [
                ChatHeader(
                  profile: _profile,
                  onBack: _goBack,
                  onMore: _showMoreSheet,
                  onProfileTap: () => Navigator.of(
                    context,
                  ).pushNamed(ProfileDetailScreen.routeName),
                ),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      AmoraSpacing.space16,
                      AmoraSpacing.space12,
                      AmoraSpacing.space16,
                      AmoraSpacing.space20 + bottomInset,
                    ),
                    children: [
                      const _DateSeparator(label: 'Today'),
                      const SizedBox(height: AmoraSpacing.space12),
                      _AiSuggestionCard(
                        onUse: () => _setInput(
                          'What is your favorite heritage cafe in Ahmedabad?',
                        ),
                        onChip: _setInput,
                      ),
                      const SizedBox(height: AmoraSpacing.space16),
                      PremiumEditorialPanel(
                        title: 'Invite $_firstName for coffee after the walk',
                        subtitle:
                            'A refined date card you can send when the conversation feels ready.',
                        badge: 'Date invite',
                        cta: 'Draft',
                        assetPath: AppImages.dateSpotCafe,
                        icon: AmoraIcons.cafe,
                        aspectRatio: 2.08,
                        onTap: () => _setInput(
                          'Would you like to try that heritage cafe this weekend? AMORA says it fits our vibe.',
                        ),
                      ),
                      const SizedBox(height: AmoraSpacing.space16),
                      const SafetyNoticeCard(),
                      const SizedBox(height: AmoraSpacing.space16),
                      for (var index = 0; index < _messages.length; index++)
                        MessageBubble(
                          key: ValueKey(_messages[index]),
                          message: _messages[index],
                          groupedWithPrevious:
                              index > 0 &&
                              _messages[index - 1].mine ==
                                  _messages[index].mine,
                          groupedWithNext:
                              index < _messages.length - 1 &&
                              _messages[index + 1].mine ==
                                  _messages[index].mine,
                        ),
                      const SizedBox(height: AmoraSpacing.space8),
                      const _TypingIndicator(),
                    ],
                  ),
                ),
                ChatInputBar(
                  controller: _controller,
                  onEmoji: _insertEmoji,
                  onSend: _send,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goBack() {
    Navigator.of(context).pushReplacementNamed(ChatListScreen.routeName);
  }

  void _setInput(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    setState(() {});
  }

  void _insertEmoji() {
    final selection = _controller.selection;
    const emoji = '\u{1F60A}';
    final text = _controller.text;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    final next = text.replaceRange(start, end, emoji);
    _controller.text = next;
    _controller.selection = TextSelection.collapsed(
      offset: start + emoji.length,
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _snack('Type a message first');
      return;
    }
    setState(() {
      _messages.add(
        ChatMessage(text: text, mine: true, time: 'Now', read: true),
      );
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _showMoreSheet() {
    showAmoraBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetAction(
            icon: AmoraIcons.profile,
            title: 'View Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(ProfileDetailScreen.routeName);
            },
          ),
          _SheetAction(
            icon: AmoraIcons.notificationsOff,
            title: 'Mute Conversation',
            onTap: () {
              Navigator.pop(context);
              _snack('Conversation muted');
            },
          ),
          _SheetAction(
            icon: AmoraIcons.report,
            title: 'Report User',
            danger: true,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(ReportFlowScreen.routeName);
            },
          ),
          _SheetAction(
            icon: AmoraIcons.block,
            title: _blocked ? 'Blocked' : 'Block User',
            danger: true,
            onTap: () {
              Navigator.pop(context);
              _showBlockDialog();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _readReceipts,
            onChanged: (value) {
              Navigator.pop(context);
              setState(() => _readReceipts = value);
              _snack(value ? 'Read receipts on' : 'Read receipts off');
            },
            title: Text('Read Receipts', style: AmoraTextStyles.titleMedium),
            secondary: const Icon(AmoraIcons.readReceipt),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog() {
    showBlockConfirmationDialog(context: context, userName: _profile.name).then(
      (blocked) {
        if (blocked != true || !mounted) return;
        setState(() => _blocked = true);
        showBlockedUserSuccessSheet(context: context, userName: _profile.name);
      },
    );
  }

  void _snack(String message) {
    showAmoraSnackBar(context, message: message);
  }
}

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.profile,
    required this.onBack,
    required this.onMore,
    required this.onProfileTap,
  });

  final DummyProfile profile;
  final VoidCallback onBack;
  final VoidCallback onMore;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;
        final veryCompact = constraints.maxWidth < 360;
        return Container(
          padding: EdgeInsets.fromLTRB(
            compact ? AmoraSpacing.space0 : AmoraSpacing.space4,
            AmoraSpacing.space8,
            compact ? AmoraSpacing.space4 : AmoraSpacing.space12,
            AmoraSpacing.space12,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: AmoraShadows.level1,
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                icon: const Icon(AmoraIcons.back),
                color: AppColors.deepWine,
              ),
              Expanded(
                child: InkWell(
                  onTap: onProfileTap,
                  borderRadius: AmoraRadius.card,
                  child: Row(
                    children: [
                      _ProfileAvatar(profile: profile),
                      if (!veryCompact) ...[
                        SizedBox(
                          width: compact
                              ? AmoraSpacing.space8
                              : AmoraSpacing.space12,
                        ),
                        Expanded(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: compact ? 110 : 150,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        profile.name.split(' ').first,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AmoraTextStyles.titleMedium
                                            .copyWith(
                                              color: AppColors.deepWine,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AmoraSpacing.space4),
                                Text(
                                  profile.status,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AmoraTextStyles.labelMedium.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'More',
                onPressed: onMore,
                icon: const Icon(AmoraIcons.moreVertical),
                color: AppColors.deepWine,
              ),
            ],
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.groupedWithPrevious = false,
    this.groupedWithNext = false,
  });

  final ChatMessage message;
  final bool groupedWithPrevious;
  final bool groupedWithNext;

  @override
  Widget build(BuildContext context) {
    final alignment = message.mine
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final bubbleColor = message.mine
        ? AppColors.primaryPurple
        : AppColors.surface;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AmoraMotion.fast,
      curve: AmoraMotion.curve,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, AmoraSpacing.space8 * (1 - value)),
          child: child,
        ),
      ),
      child: Semantics(
        label:
            '${message.mine ? 'Sent' : 'Received'} message at ${message.time}: ${message.text}',
        child: Align(
          alignment: alignment,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: (MediaQuery.sizeOf(context).width * .76)
                  .clamp(240.0, 420.0)
                  .toDouble(),
            ),
            margin: EdgeInsets.only(
              bottom: groupedWithNext
                  ? AmoraSpacing.space4
                  : AmoraSpacing.space12,
            ),
            padding: const EdgeInsets.fromLTRB(
              AmoraSpacing.space16,
              AmoraSpacing.space12,
              AmoraSpacing.space16,
              AmoraSpacing.space8,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                  !message.mine && groupedWithPrevious
                      ? AmoraRadius.small
                      : AmoraRadius.extraLarge,
                ),
                topRight: Radius.circular(
                  message.mine && groupedWithPrevious
                      ? AmoraRadius.small
                      : AmoraRadius.extraLarge,
                ),
                bottomLeft: Radius.circular(
                  message.mine ? AmoraRadius.extraLarge : AmoraRadius.small,
                ),
                bottomRight: Radius.circular(
                  message.mine ? AmoraRadius.small : AmoraRadius.extraLarge,
                ),
              ),
              border: message.mine
                  ? null
                  : Border.all(color: AppColors.borderGray),
              boxShadow: AmoraShadows.level1,
            ),
            child: Column(
              crossAxisAlignment: message.mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: AmoraTextStyles.bodyMedium.copyWith(
                    color: message.mine
                        ? AppColors.surface
                        : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.time,
                      style: AmoraTextStyles.labelSmall.copyWith(
                        color: message.mine
                            ? AppColors.surface
                            : AppColors.textGray,
                      ),
                    ),
                    if (message.mine) ...[
                      const SizedBox(width: AmoraSpacing.space4),
                      Icon(
                        message.read
                            ? AmoraIcons.readReceipt
                            : AmoraIcons.check,
                        size: AmoraIconSizes.small,
                        color: AppColors.surface,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onEmoji,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onEmoji;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AmoraSpacing.space12,
        AmoraSpacing.space8,
        AmoraSpacing.space12,
        AmoraSpacing.space12 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderGray)),
        boxShadow: AmoraShadows.bottomSheet,
      ),
      child: Row(
        children: [
          _InputIconButton(
            icon: AmoraIcons.emoji,
            label: 'Emoji',
            onTap: onEmoji,
          ),
          Expanded(
            child: AppTextField(
              controller: controller,
              label: 'Message',
              hint: 'Write a thoughtful reply',
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
            ),
          ),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: onSend,
            icon: const Icon(AmoraIcons.send),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: AppColors.surface,
              minimumSize: const Size.square(AmoraSpacing.minimumTouchTarget),
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyNoticeCard extends StatelessWidget {
  const SafetyNoticeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      radius: AmoraRadius.large,
      color: AppColors.surface,
      child: Row(
        children: [
          const Icon(
            AmoraIcons.shield,
            color: AppColors.successGreen,
            size: AmoraIconSizes.medium,
          ),
          const SizedBox(width: AmoraSpacing.space12),
          Expanded(
            child: Text(
              'Never share financial details. Report suspicious behavior.',
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.mine,
    required this.time,
    this.read = false,
  });

  final String text;
  final bool mine;
  final String time;
  final bool read;
}

class _AiSuggestionCard extends StatelessWidget {
  const _AiSuggestionCard({required this.onUse, required this.onChip});

  final VoidCallback onUse;
  final ValueChanged<String> onChip;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      radius: AmoraRadius.extraLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AmoraIcons.ai, color: AppColors.premiumGold, size: 21),
              const SizedBox(width: AmoraSpacing.space8),
              Text(
                'AI Icebreaker',
                style: AmoraTextStyles.titleMedium.copyWith(
                  color: AppColors.deepWine,
                ),
              ),
            ],
          ),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            'Try asking about ${_chatProfile.interests.first.toLowerCase()} in ${_chatProfile.city}.',
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space12),
          Align(
            alignment: Alignment.centerLeft,
            child: AppPrimaryButton(
              label: 'Use suggestion',
              size: AmoraButtonSize.compact,
              fullWidth: false,
              onPressed: onUse,
              icon: AmoraIcons.edit,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space12),
          Wrap(
            spacing: AmoraSpacing.space8,
            runSpacing: AmoraSpacing.space8,
            children: [
              _AiChip(
                label: 'Smart Reply',
                onTap: () => onChip(
                  'That sounds lovely. What made you pick that place?',
                ),
              ),
              _AiChip(
                label: 'Ice Breaker',
                onTap: () =>
                    onChip('What is one weekend ritual you always protect?'),
              ),
              _AiChip(
                label: 'Emoji',
                onTap: () => onChip('That made me smile.'),
              ),
              _AiChip(
                label: 'Translate',
                onTap: () => onChip('I can say that in Hindi or Gujarati too.'),
              ),
              _AiChip(
                label: 'Summary',
                onTap: () => onChip(
                  'So far we both like heritage walks, coffee, and easy conversation.',
                ),
              ),
              _AiChip(
                label: 'Health',
                onTap: () => onChip(
                  'This conversation feels warm, balanced, and respectful.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiChip extends StatelessWidget {
  const _AiChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AmoraFilterChip(
      label: label,
      selected: false,
      icon: AmoraIcons.ai,
      onSelected: (_) => onTap(),
    );
  }
}

class _InputIconButton extends StatelessWidget {
  const _InputIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onTap,
      icon: Icon(icon),
      color: AppColors.primary,
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(child: AmoraBadge.status(label: label));
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AmoraSpacing.space4,
        top: AmoraSpacing.space4,
      ),
      child: Row(
        children: [
          Text(
            '${_chatProfile.name.split(' ').first} is typing...',
            style: AmoraTextStyles.labelMedium.copyWith(
              color: AppColors.successGreen,
            ),
          ),
          const SizedBox(width: AmoraSpacing.space8),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Opacity(
                      opacity: ((_controller.value + i * .22) % 1) < .55
                          ? 1
                          : .35,
                      child: Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(
                          right: AmoraSpacing.space4,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.successGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    return PremiumAvatar(
      imageUrl: profile.imageUrl,
      fallbackAsset: profile.fallbackAsset,
      initials: profile.initials,
      radius: AmoraSpacing.space24,
      online: true,
      verified: true,
      semanticLabel: '${profile.name} profile photo',
    );
  }
}

final _chatProfile = ImageRepository.profileByName('Aadhya');

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.errorRed : AppColors.deepWine;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .10),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: AmoraTextStyles.titleMedium.copyWith(color: color),
      ),
      trailing: const Icon(AmoraIcons.forward),
    );
  }
}

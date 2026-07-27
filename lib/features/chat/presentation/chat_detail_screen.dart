import 'package:amora_ai/core/data/amora_dummy_data.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_bottom_sheet.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/chat/presentation/chat_list_screen.dart';
import 'package:amora_ai/features/chat/presentation/widgets/chat_presence_avatar.dart';
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
  bool get _online {
    for (final chat in AmoraDummyData.chats) {
      if (chat.user.id == _profile.id) return chat.online;
    }
    return false;
  }

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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 760,
          child: Column(
            children: [
              ChatHeader(
                profile: _profile,
                online: _online,
                onBack: _goBack,
                onMore: _showMoreSheet,
                onProfileTap: () => Navigator.of(
                  context,
                ).pushNamed(ProfileDetailScreen.routeName),
              ),
              Expanded(
                child: _ChatTimeline(
                  messages: _messages,
                  profile: _profile,
                  scrollController: _scrollController,
                  showReadReceipts: _readReceipts,
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
    );
  }

  Future<void> _goBack() async {
    if (await Navigator.of(context).maybePop()) return;
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(ChatListScreen.routeName);
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
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
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
            activeThumbColor: AppColors.surface,
            activeTrackColor: AppColors.secondary,
            title: const Text(
              'Read Receipts',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            secondary: const Icon(
              AmoraIcons.readReceipt,
              color: AppColors.primary,
            ),
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
    required this.online,
    required this.onBack,
    required this.onMore,
    required this.onProfileTap,
  });

  final DummyProfile profile;
  final bool online;
  final VoidCallback onBack;
  final VoidCallback onMore;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shadowColor: AppColors.primary.withValues(alpha: .08),
      elevation: 1,
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            _HeaderIconButton(
              tooltip: 'Back',
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
            ),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Open ${profile.name} profile',
                child: InkWell(
                  onTap: onProfileTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChatPresenceAvatar(
                          profile: profile,
                          radius: 21,
                          online: online,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name.split(' ').first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 20,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (online) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'Online',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.text.withValues(
                                      alpha: .66,
                                    ),
                                    fontSize: 12,
                                    height: 1.2,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _HeaderIconButton(
              tooltip: 'More',
              icon: Icons.more_horiz_rounded,
              onPressed: onMore,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.background,
          hoverColor: AppColors.tertiary.withValues(alpha: .24),
          focusColor: AppColors.tertiary.withValues(alpha: .28),
          highlightColor: AppColors.tertiary.withValues(alpha: .2),
          side: BorderSide(color: AppColors.secondary.withValues(alpha: .16)),
        ),
        icon: Icon(icon, size: 21),
      ),
    );
  }
}

class _ChatTimeline extends StatelessWidget {
  const _ChatTimeline({
    required this.messages,
    required this.profile,
    required this.scrollController,
    required this.showReadReceipts,
  });

  final List<ChatMessage> messages;
  final DummyProfile profile;
  final ScrollController scrollController;
  final bool showReadReceipts;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const _EmptyConversationState();
    }
    final itemCount = messages.length + 1;
    return ListView.builder(
      key: const PageStorageKey<String>('chat-message-timeline'),
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: ChatDateDivider(label: 'Today'),
          );
        }
        final messageIndex = index - 1;
        final message = messages[messageIndex];
        final groupedWithPrevious =
            messageIndex > 0 && messages[messageIndex - 1].mine == message.mine;
        final groupedWithNext =
            messageIndex < messages.length - 1 &&
            messages[messageIndex + 1].mine == message.mine;
        return MessageBubble(
          key: ValueKey(
            'message-$messageIndex-${message.time}-${message.mine}',
          ),
          message: message,
          profile: profile,
          groupedWithPrevious: groupedWithPrevious,
          groupedWithNext: groupedWithNext,
          showReadReceipt: showReadReceipts,
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.profile,
    this.groupedWithPrevious = false,
    this.groupedWithNext = false,
    this.showReadReceipt = true,
  });

  final ChatMessage message;
  final DummyProfile profile;
  final bool groupedWithPrevious;
  final bool groupedWithNext;
  final bool showReadReceipt;

  @override
  Widget build(BuildContext context) {
    final showMetadata = !groupedWithNext;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AmoraMotion.fast,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(
            message.mine ? 10 * (1 - value) : -10 * (1 - value),
            4 * (1 - value),
          ),
          child: child,
        ),
      ),
      child: Semantics(
        label:
            '${message.mine ? 'Sent' : 'Received'} message at ${message.time}: ${message.text}',
        child: Padding(
          padding: EdgeInsets.only(bottom: groupedWithNext ? 4 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: message.mine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!message.mine) ...[
                if (groupedWithNext)
                  const SizedBox(width: 32)
                else
                  PremiumAvatar(
                    imageUrl: profile.imageUrl,
                    fallbackAsset: profile.fallbackAsset,
                    initials: profile.initials,
                    radius: 14,
                    semanticLabel: '${profile.name} profile photo',
                  ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: EdgeInsets.fromLTRB(
                    15,
                    11,
                    15,
                    showMetadata ? 8 : 11,
                  ),
                  decoration: BoxDecoration(
                    color: message.mine ? AppColors.primary : AppColors.surface,
                    borderRadius: _bubbleRadius,
                    border: message.mine
                        ? null
                        : Border.all(color: AppColors.tertiary),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .07),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: message.mine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.mine
                              ? AppColors.surface
                              : AppColors.text,
                          fontSize: 16,
                          height: 1.38,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (showMetadata) ...[
                        const SizedBox(height: 5),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.time,
                              style: TextStyle(
                                color: message.mine
                                    ? AppColors.surface.withValues(alpha: .78)
                                    : AppColors.text.withValues(alpha: .62),
                                fontSize: 12,
                                height: 1.2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (message.mine && showReadReceipt) ...[
                              const SizedBox(width: 5),
                              Icon(
                                message.read
                                    ? AmoraIcons.readReceipt
                                    : AmoraIcons.check,
                                size: AmoraIconSizes.small,
                                color: AppColors.surface,
                                semanticLabel: message.read ? 'Read' : 'Sent',
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (message.mine) const SizedBox(width: 2),
            ],
          ),
        ),
      ),
    );
  }

  BorderRadius get _bubbleRadius {
    const large = Radius.circular(22);
    const grouped = Radius.circular(8);
    const tail = Radius.circular(6);
    if (message.mine) {
      return BorderRadius.only(
        topLeft: large,
        topRight: groupedWithPrevious ? grouped : large,
        bottomLeft: large,
        bottomRight: groupedWithNext ? grouped : tail,
      );
    }
    return BorderRadius.only(
      topLeft: groupedWithPrevious ? grouped : large,
      topRight: large,
      bottomLeft: groupedWithNext ? grouped : tail,
      bottomRight: large,
    );
  }
}

class ChatDateDivider extends StatelessWidget {
  const ChatDateDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.tertiary),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, required this.profile});

  final DummyProfile profile;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
    } else if (!_animation.isAnimating) {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      liveRegion: true,
      label: '${widget.profile.name} is typing',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          PremiumAvatar(
            imageUrl: widget.profile.imageUrl,
            fallbackAsset: widget.profile.fallbackAsset,
            initials: widget.profile.initials,
            radius: 14,
            semanticLabel: '${widget.profile.name} profile photo',
          ),
          const SizedBox(width: 8),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.tertiary),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: reduceMotion
                ? const _TypingDots(opacities: <double>[1, .65, .35])
                : AnimatedBuilder(
                    animation: _animation,
                    builder: (context, _) {
                      return _TypingDots(
                        opacities: <double>[
                          for (var index = 0; index < 3; index++)
                            ((_animation.value + index * .2) % 1) < .55
                                ? 1
                                : .3,
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatelessWidget {
  const _TypingDots({required this.opacities});

  final List<double> opacities;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < opacities.length; index++) ...[
          Opacity(
            opacity: opacities[index],
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: 7),
            ),
          ),
          if (index != opacities.length - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }
}

class _EmptyConversationState extends StatelessWidget {
  const _EmptyConversationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: .22),
                ),
              ),
              child: const Icon(
                Icons.waving_hand_rounded,
                color: AppColors.secondary,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Start the conversation',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Say hello 👋',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text.withValues(alpha: .66),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatInputBar extends StatefulWidget {
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
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focusNode
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    final hasText = widget.controller.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.tertiary.withValues(alpha: .38)),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.fromLTRB(4, 4, 5, 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: focused ? AppColors.secondary : AppColors.tertiary,
            width: focused ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: focused ? .14 : .09),
              blurRadius: focused ? 22 : 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ChatAttachmentButton(
              tooltip: 'Emoji',
              icon: Icons.sentiment_satisfied_alt_rounded,
              onPressed: widget.onEmoji,
            ),
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
                decoration: const InputDecoration(
                  hintText: 'Write a message...',
                  hintStyle: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            ChatSendButton(emphasized: hasText, onPressed: widget.onSend),
          ],
        ),
      ),
    );
  }
}

class ChatAttachmentButton extends StatelessWidget {
  const ChatAttachmentButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: AppColors.primary,
        icon: Icon(icon, size: 22),
      ),
    );
  }
}

class ChatSendButton extends StatefulWidget {
  const ChatSendButton({
    super.key,
    required this.emphasized,
    required this.onPressed,
  });

  final bool emphasized;
  final VoidCallback onPressed;

  @override
  State<ChatSendButton> createState() => _ChatSendButtonState();
}

class _ChatSendButtonState extends State<ChatSendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Send',
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? .92 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: widget.emphasized ? AppColors.primary : AppColors.tertiary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Send',
              onPressed: widget.onPressed,
              color: widget.emphasized ? AppColors.surface : AppColors.primary,
              icon: const Icon(Icons.arrow_upward_rounded, size: 22),
            ),
          ),
        ),
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
    final color = danger ? AppColors.secondary : AppColors.primary;
    return ListTile(
      minTileHeight: 56,
      onTap: onTap,
      leading: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: 42,
          child: Icon(icon, color: color, size: 21),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.primary,
      ),
    );
  }
}

import 'dart:async';
import 'dart:typed_data';

import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/core/api/phase_two_api_service.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_header_tokens.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_bottom_sheet.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/chat/presentation/chat_list_screen.dart';
import 'package:amora_ai/features/chat/data/chat_repository.dart';
import 'package:amora_ai/features/chat/presentation/widgets/chat_presence_avatar.dart';
import 'package:amora_ai/features/chat/presentation/widgets/amora_chat_composer.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:amora_ai/features/safety/presentation/blocked_user_success_sheet.dart';
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
import 'package:amora_ai/features/safety/widgets/block_confirmation_dialog.dart';
import 'package:flutter/material.dart';

class ChatDetailArgs {
  const ChatDetailArgs({
    required this.conversationId,
    this.recipientId,
    this.profileId,
    this.recipientName,
    this.recipientImage,
    this.recipientStatus,
    this.prefillText,
    this.messageContext,
  });

  final String conversationId;
  final String? recipientId;
  final String? profileId;
  final String? recipientName;
  final String? recipientImage;
  final String? recipientStatus;
  final String? prefillText;
  final ChatMessageContext? messageContext;
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
  final _repository = ChatRepository.instance;
  StreamSubscription<ChatConversation>? _conversationSubscription;
  Timer? _draftTimer;
  bool _seedApplied = false;
  bool _readReceipts = true;
  bool _loading = true;
  bool _sending = false;
  bool _loadingOlder = false;
  bool _emojiPickerVisible = false;
  Object? _error;
  String? _conversationId;
  String? _recipientId;
  ChatConversation? _conversation;
  ChatMessageContext? _pendingContext;

  DummyProfile get _profile => _conversation!.user;
  bool get _online => _conversation?.online ?? false;
  List<ChatMessage> get _messages =>
      _conversation?.messages ?? const <ChatMessage>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seedApplied) return;
    _seedApplied = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ChatDetailArgs) {
      _conversationId = args.conversationId;
      _recipientId = args.recipientId ?? args.profileId;
      _pendingContext = args.messageContext;
      final initialDraft = args.prefillText?.trim().isNotEmpty == true
          ? args.prefillText!
          : _repository.draftForConversation(args.conversationId);
      _controller.text = initialDraft;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
    _loadConversation();
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    final conversationId = _conversationId;
    if (conversationId != null) {
      unawaited(_repository.saveDraft(conversationId, _controller.text));
    }
    unawaited(_conversationSubscription?.cancel());
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
          child: LayoutBuilder(
            builder: (context, constraints) =>
                _buildConversation(compactHeight: constraints.maxHeight < 700),
          ),
        ),
      ),
    );
  }

  Widget _buildConversation({required bool compactHeight}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _conversation == null) {
      return _ConversationLoadError(
        onBack: _goBack,
        onRetry: _loadConversation,
      );
    }
    return Column(
      children: [
        if (!(compactHeight && _emojiPickerVisible))
          ChatHeader(
            profile: _profile,
            online: _online,
            status: _online
                ? 'Online'
                : _profile.status.trim().isEmpty
                ? 'Offline'
                : _profile.status.trim(),
            onBack: _goBack,
            onMore: _showMoreSheet,
            onProfileTap: () => Navigator.of(
              context,
            ).pushNamed(ProfileDetailScreen.routeName, arguments: _profile),
          ),
        Expanded(
          child: _ChatTimeline(
            messages: _messages,
            profile: _profile,
            scrollController: _scrollController,
            showReadReceipts: _readReceipts,
            onRetry: _retryMessage,
            onDelete: _confirmDeleteMessage,
            hasMore: _conversation!.hasMoreMessages,
            loadingOlder: _loadingOlder,
            onLoadOlder: _loadOlder,
          ),
        ),
        AmoraChatComposer(
          controller: _controller,
          sending: _sending,
          onSend: _send,
          onAttach: _sendPhoto,
          onDraftChanged: _saveDraft,
          enabled: _conversation!.canMessage,
          disabledReason:
              _conversation!.unavailableReason ??
              'This conversation is no longer available.',
          compactHeight: compactHeight,
          contextLabel:
              _pendingContext?.type == ChatMessageContextType.profilePrompt
              ? 'Replying to profile prompt'
              : null,
          contextTitle: _pendingContext?.title,
          contextDetail: _pendingContext?.detail,
          onRemoveContext: _pendingContext == null
              ? null
              : () => setState(() => _pendingContext = null),
          onEmojiPickerVisibilityChanged: (visible) {
            if (mounted && _emojiPickerVisible != visible) {
              setState(() => _emojiPickerVisible = visible);
            }
          },
        ),
      ],
    );
  }

  Future<void> _loadConversation() async {
    var conversationId = _conversationId;
    if ((conversationId == null || conversationId.isEmpty) &&
        _recipientId != null) {
      try {
        conversationId = await _repository.createConversationForUserId(
          _recipientId!,
        );
        _conversationId = conversationId;
      } catch (error) {
        _error = error;
      }
    }
    if (conversationId == null || conversationId.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = StateError('Missing conversation id');
        });
      }
      return;
    }
    final resolvedConversationId = conversationId;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      await _conversationSubscription?.cancel();
      _conversationSubscription = null;
      final conversation = await _repository.loadConversation(
        resolvedConversationId,
      );
      if (conversation == null) throw StateError('Conversation not found');
      await _repository.markRead(resolvedConversationId);
      if (!mounted) return;
      setState(() {
        _conversation = _repository.conversation(resolvedConversationId);
        if (_controller.text.isEmpty && conversation.draft.isNotEmpty) {
          _controller.text = conversation.draft;
          _controller.selection = TextSelection.collapsed(
            offset: _controller.text.length,
          );
        }
        _loading = false;
      });
      _conversationSubscription = _repository
          .watchConversation(resolvedConversationId)
          .listen(_handleConversationUpdate);
      _scrollToNewest(jump: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _goBack() async {
    if (await Navigator.of(context).maybePop()) return;
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(ChatListScreen.routeName);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final conversationId = _conversationId;
    if (text.isEmpty || conversationId == null || _sending) return;
    if (text.length > AmoraChatComposer.maximumMessageLength) return;
    setState(() => _sending = true);
    try {
      final context = _pendingContext;
      final updated = await _repository.sendMessage(
        conversationId,
        text,
        context: context,
      );
      if (updated == null) throw StateError('Conversation not found');
      if (!mounted) return;
      setState(() {
        _conversation = updated;
        _controller.clear();
        _pendingContext = null;
      });
      await _repository.clearDraft(conversationId);
    } catch (_) {
      if (mounted) {
        _snack(
          _pendingContext?.type == ChatMessageContextType.profilePrompt
              ? 'Couldn’t send your reply. Try again.'
              : 'Message could not be sent. Try again.',
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    _scrollToNewest();
  }

  Future<void> _retryMessage(ChatMessage message) async {
    final conversationId = _conversationId;
    if (conversationId == null || message.status != ChatMessageStatus.failed) {
      return;
    }
    try {
      await _repository.retryMessage(conversationId, message.id);
    } catch (_) {
      if (mounted) _snack('Message is still queued. Try again when connected.');
    }
  }

  Future<void> _sendPhoto() async {
    final conversationId = _conversationId;
    if (conversationId == null || _sending) return;
    const picker = DeviceAmoraMediaPicker();
    final result = await picker.pickImage(source: AmoraMediaSource.gallery);
    if (!mounted) return;
    if (!result.succeeded) {
      showAmoraMediaResult(
        context,
        result: result,
        picker: picker,
        onRetry: _sendPhoto,
      );
      return;
    }
    if (result.media!.byteLength > 10 * 1024 * 1024) {
      _snack('Choose an image smaller than 10 MB.');
      return;
    }
    setState(() => _sending = true);
    try {
      await _repository.sendMedia(conversationId, result.media!);
      _scrollToNewest();
    } catch (_) {
      if (mounted) _snack('Photo could not be sent. Try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _loadOlder() async {
    final conversationId = _conversationId;
    if (conversationId == null || _loadingOlder) return;
    setState(() => _loadingOlder = true);
    try {
      await _repository.loadConversation(conversationId, older: true);
    } catch (_) {
      if (mounted) _snack('Older messages could not be loaded.');
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  Future<void> _confirmDeleteMessage(ChatMessage message) async {
    if (!message.mine || message.deleted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text(
          'This message will be replaced with a deleted-message marker.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deleteMessage(message.id);
    } catch (_) {
      if (mounted) _snack('Message could not be deleted.');
    }
  }

  void _saveDraft(String value) {
    final conversationId = _conversationId;
    if (conversationId == null) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_repository.saveDraft(conversationId, value)),
    );
  }

  void _handleConversationUpdate(ChatConversation conversation) {
    if (!mounted || conversation.id != _conversationId) return;
    final previousCount = _conversation?.messages.length ?? 0;
    setState(() => _conversation = conversation);
    if (conversation.unread > 0) {
      unawaited(_repository.markRead(conversation.id));
    }
    if (conversation.messages.length > previousCount) _scrollToNewest();
  }

  void _scrollToNewest({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final offset = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(offset);
      } else {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
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
            title: _conversation?.canMessage == false
                ? 'Blocked'
                : 'Block User',
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

  Future<void> _showBlockDialog() async {
    if (_conversation?.canMessage == false ||
        ProfileRelationshipController.instance.isBlocked(_profile.id)) {
      return;
    }
    final blocked = await showBlockConfirmationDialog(
      context: context,
      userName: _profile.name,
      onConfirm: () async {
        final conversationId = _conversationId;
        if (conversationId != null) {
          await _repository.setMessagingAvailability(
            conversationId,
            canMessage: false,
            reason: 'You blocked this member. Messaging is disabled.',
          );
        }
        await PhaseTwoApiService.instance.block(_profile.id);
        ProfileRelationshipController.instance.blockProfile(_profile);
      },
    );
    if (blocked != true || !mounted) return;
    await showBlockedUserSuccessSheet(
      context: context,
      userName: _profile.name,
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
    required this.status,
    required this.onBack,
    required this.onMore,
    required this.onProfileTap,
  });

  final DummyProfile profile;
  final bool online;
  final String status;
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
        height: AmoraHeaderTokens.chatDetailHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AmoraHeaderTokens.pageHorizontalInset,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _HeaderIconButton(
                key: const ValueKey('chat-header-back'),
                tooltip: 'Back',
                icon: Icons.arrow_back_rounded,
                onPressed: onBack,
              ),
              const SizedBox(width: AmoraHeaderTokens.backTitleGap),
              Expanded(
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  button: true,
                  label:
                      'Open ${profile.name} profile${profile.verified ? ', verified' : ''}, $status',
                  child: InkWell(
                    key: const ValueKey('chat-header-identity'),
                    excludeFromSemantics: true,
                    onTap: onProfileTap,
                    borderRadius: BorderRadius.circular(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Semantics(
                          image: true,
                          label: 'Chat profile picture for ${profile.name}',
                          excludeSemantics: true,
                          child: ChatPresenceAvatar(
                            key: const ValueKey('chat-header-avatar'),
                            profile: profile,
                            radius: 20,
                            online: online,
                            showVerified: false,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            key: const ValueKey('chat-header-name-status'),
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      profile.name,
                                      key: const ValueKey('chat-header-name'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.left,
                                      style: AmoraTextStyles.titleMedium
                                          .copyWith(
                                            color: AppColors.text,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  if (profile.verified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified_rounded,
                                      key: ValueKey('chat-header-verified'),
                                      size: 16,
                                      color: AppColors.secondary,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                status,
                                key: const ValueKey('chat-header-status'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                                style: AmoraTextStyles.bodySmall.copyWith(
                                  color: AppColors.text.withValues(alpha: .66),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AmoraHeaderTokens.actionGap),
              _HeaderIconButton(
                key: const ValueKey('chat-header-more'),
                tooltip: 'More chat options',
                icon: Icons.more_horiz_rounded,
                onPressed: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
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
      dimension: AmoraHeaderTokens.touchTarget,
      child: Center(
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          constraints: const BoxConstraints.tightFor(
            width: AmoraHeaderTokens.actionVisualSize,
            height: AmoraHeaderTokens.actionVisualSize,
          ),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: AppColors.background,
            hoverColor: AppColors.tertiary.withValues(alpha: .24),
            focusColor: AppColors.tertiary.withValues(alpha: .28),
            highlightColor: AppColors.tertiary.withValues(alpha: .2),
            side: BorderSide(color: AppColors.secondary.withValues(alpha: .16)),
          ),
          icon: Icon(icon, size: AmoraHeaderTokens.chatIconSize),
        ),
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
    required this.onRetry,
    required this.onDelete,
    required this.hasMore,
    required this.loadingOlder,
    required this.onLoadOlder,
  });

  final List<ChatMessage> messages;
  final DummyProfile profile;
  final ScrollController scrollController;
  final bool showReadReceipts;
  final ValueChanged<ChatMessage> onRetry;
  final ValueChanged<ChatMessage> onDelete;
  final bool hasMore;
  final bool loadingOlder;
  final VoidCallback onLoadOlder;

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
          return Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: Column(
              children: [
                if (hasMore)
                  TextButton(
                    onPressed: loadingOlder ? null : onLoadOlder,
                    child: Text(
                      loadingOlder ? 'Loading…' : 'Load older messages',
                    ),
                  ),
                const ChatDateDivider(label: 'Today'),
              ],
            ),
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
          key: ValueKey(message.id),
          message: message,
          profile: profile,
          groupedWithPrevious: groupedWithPrevious,
          groupedWithNext: groupedWithNext,
          showReadReceipt: showReadReceipts,
          onRetry: () => onRetry(message),
          onDelete: message.mine ? () => onDelete(message) : null,
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
    this.onRetry,
    this.onDelete,
  });

  final ChatMessage message;
  final DummyProfile profile;
  final bool groupedWithPrevious;
  final bool groupedWithNext;
  final bool showReadReceipt;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;

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
        child: GestureDetector(
          onLongPress: onDelete,
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
                      color: message.mine
                          ? AppColors.primary
                          : AppColors.surface,
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
                        if (message.context != null) ...[
                          _MessageContextCard(
                            context: message.context!,
                            mine: message.mine,
                          ),
                          if (!_isRoseWithoutNote) const SizedBox(height: 8),
                        ],
                        if (message.deleted)
                          Text(
                            'Message deleted',
                            style: TextStyle(
                              color: message.mine
                                  ? AppColors.surface.withValues(alpha: .75)
                                  : AppColors.text.withValues(alpha: .65),
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else if (message.type == 'image' &&
                            message.mediaUrl != null) ...[
                          FutureBuilder<Uint8List>(
                            future: ChatRepository.instance.mediaBytes(
                              message.mediaUrl!,
                            ),
                            builder: (context, snapshot) => ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: snapshot.hasData
                                  ? Image.memory(
                                      snapshot.data!,
                                      width: 240,
                                      height: 220,
                                      fit: BoxFit.cover,
                                    )
                                  : const SizedBox(
                                      width: 240,
                                      height: 160,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                            ),
                          ),
                          if (message.text.isNotEmpty)
                            const SizedBox(height: 8),
                          if (message.text.isNotEmpty)
                            Text(
                              message.text,
                              style: TextStyle(
                                color: message.mine
                                    ? AppColors.surface
                                    : AppColors.text,
                                fontSize: 16,
                              ),
                            ),
                        ] else if (!_isRoseWithoutNote)
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
                                _MessageDeliveryState(
                                  status: message.status,
                                  onRetry: onRetry,
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
      ),
    );
  }

  bool get _isRoseWithoutNote =>
      message.context?.type == ChatMessageContextType.rose &&
      message.text.trim().toLowerCase() == 'rose';

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

class _MessageContextCard extends StatelessWidget {
  const _MessageContextCard({required this.context, required this.mine});

  final ChatMessageContext context;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final foreground = mine ? AppColors.surface : AppColors.text;
    final muted = foreground.withValues(alpha: .74);
    final isRose = this.context.type == ChatMessageContextType.rose;
    return Semantics(
      label: isRose
          ? 'Rose. Sent from Profile Detail.'
          : 'Reply to profile prompt. ${this.context.title}. ${this.context.detail}',
      child: Container(
        key: ValueKey(
          isRose ? 'rose-chat-message' : 'prompt-reply-chat-context',
        ),
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: mine
              ? AppColors.surface.withValues(alpha: .13)
              : AppColors.tertiary.withValues(alpha: .30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: mine
                ? AppColors.surface.withValues(alpha: .24)
                : AppColors.secondary.withValues(alpha: .30),
          ),
        ),
        child: isRose
            ? Row(
                children: [
                  Icon(
                    Icons.local_florist_rounded,
                    color: mine ? AppColors.surface : AppColors.secondary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rose',
                          style: TextStyle(
                            color: foreground,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          this.context.detail,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reply to profile prompt',
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '“${this.context.title}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    this.context.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
      ),
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

class _ConversationLoadError extends StatelessWidget {
  const _ConversationLoadError({required this.onBack, required this.onRetry});

  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
              size: 42,
            ),
            const SizedBox(height: 16),
            const Text(
              'Conversation unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We could not load this conversation. Try again or return to Chats.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text.withValues(alpha: .68),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton(onPressed: onBack, child: const Text('Back')),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageDeliveryState extends StatelessWidget {
  const _MessageDeliveryState({required this.status, this.onRetry});

  final ChatMessageStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (status) {
      ChatMessageStatus.sending => (null, 'Sending'),
      ChatMessageStatus.queued => (Icons.cloud_off_outlined, 'Queued'),
      ChatMessageStatus.sent => (AmoraIcons.check, 'Sent'),
      ChatMessageStatus.delivered => (AmoraIcons.readReceipt, 'Delivered'),
      ChatMessageStatus.read => (AmoraIcons.readReceipt, 'Read'),
      ChatMessageStatus.failed => (Icons.error_outline_rounded, 'Failed'),
    };
    final state = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == ChatMessageStatus.sending)
          const SizedBox.square(
            dimension: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.surface,
            ),
          )
        else
          Icon(icon, size: AmoraIconSizes.small, color: AppColors.surface),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.surface,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    if (status != ChatMessageStatus.failed || onRetry == null) return state;
    return Semantics(
      button: true,
      label: 'Message failed. Retry sending',
      child: InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: state,
        ),
      ),
    );
  }
}

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

import 'package:amora_ai/core/data/amora_dummy_data.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_bottom_sheet.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/chat/presentation/widgets/chat_presence_avatar.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key, this.showNavigation = true});

  final bool showNavigation;

  static const routeName = '/chats';

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';
  ChatInboxFilter _filter = ChatInboxFilter.all;

  List<DummyConversation> get _allChats => AmoraDummyData.chats;

  List<DummyConversation> get _activeChats {
    final participantIds = <String>{};
    return _allChats
        .where((chat) => chat.online && participantIds.add(chat.user.id))
        .toList(growable: false);
  }

  List<DummyConversation> get _visibleChats {
    final normalizedQuery = _query.trim().toLowerCase();
    return _allChats
        .where((chat) {
          final matchesFilter = switch (_filter) {
            ChatInboxFilter.all => true,
            ChatInboxFilter.unread => chat.unread > 0,
            ChatInboxFilter.online => chat.online,
          };
          if (!matchesFilter) return false;
          if (normalizedQuery.isEmpty) return true;
          return chat.user.name.toLowerCase().contains(normalizedQuery) ||
              chat.lastMessage.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  int get _unreadTotal =>
      _allChats.fold<int>(0, (total, chat) => total + chat.unread);

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardIsOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final visibleChats = _visibleChats;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: !widget.showNavigation,
        child: ResponsiveMobileFrame(
          maxWidth: 680,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AmoraSpacing.space16,
                  AmoraSpacing.space8,
                  AmoraSpacing.space16,
                  AmoraSpacing.space12,
                ),
                child: Column(
                  children: [
                    ChatsAppBar(
                      unreadCount: _unreadTotal,
                      onSearch: _focusSearch,
                      onCompose: _showComposeSheet,
                      onMore: _showInboxMenu,
                    ),
                    const SizedBox(height: AmoraSpacing.space12),
                    ChatSearchField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      hasQuery: _query.isNotEmpty,
                      onChanged: (value) => setState(() => _query = value),
                      onClear: _clearSearch,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    CustomScrollView(
                      key: const PageStorageKey<String>('chats-inbox-scroll'),
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        if (_activeChats.isNotEmpty && _query.isEmpty)
                          SliverToBoxAdapter(
                            child: ActiveMatchesSection(
                              chats: _activeChats,
                              onOpen: _openConversation,
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AmoraSpacing.space16,
                              AmoraSpacing.space8,
                              AmoraSpacing.space16,
                              AmoraSpacing.space12,
                            ),
                            child: ChatFilterBar(
                              selected: _filter,
                              onSelected: (filter) =>
                                  setState(() => _filter = filter),
                            ),
                          ),
                        ),
                        if (_allChats.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: ChatsEmptyState(
                              onDiscover: () => Navigator.of(
                                context,
                              ).pushReplacementNamed('/browse'),
                            ),
                          )
                        else if (visibleChats.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: ChatsSearchEmptyState(
                              hasQuery: _query.isNotEmpty,
                              onClear: _clearSearchAndFilter,
                            ),
                          )
                        else ...[
                          const SliverToBoxAdapter(
                            child: ConversationSectionHeader(
                              title: 'Conversations',
                            ),
                          ),
                          SliverList.builder(
                            itemCount: visibleChats.length,
                            itemBuilder: (context, index) {
                              final chat = visibleChats[index];
                              return ConversationTile(
                                key: ValueKey('conversation-${chat.id}'),
                                chat: chat,
                                onOpen: () => _openConversation(chat),
                                onOpenProfile: _openProfile,
                                onLongPress: () =>
                                    _showConversationActions(chat),
                              );
                            },
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: keyboardIsOpen
                                  ? AmoraSpacing.space16
                                  : widget.showNavigation
                                  ? FloatingBottomNav.contentBottomPadding
                                  : AmoraSpacing.space16,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (widget.showNavigation && !keyboardIsOpen)
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: FloatingBottomNav(activeTab: AmoraNavTab.chats),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  void _focusSearch() {
    _searchFocusNode.requestFocus();
  }

  void _clearSearchAndFilter() {
    _searchController.clear();
    setState(() {
      _query = '';
      _filter = ChatInboxFilter.all;
    });
  }

  void _openConversation(DummyConversation chat) {
    Navigator.of(context).pushNamed(ChatDetailScreen.routeName);
  }

  void _openProfile() {
    Navigator.of(context).pushNamed(ProfileDetailScreen.routeName);
  }

  void _showComposeSheet() {
    showAmoraBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InboxSheetHeader(
            title: 'New message',
            supporting: 'Continue a conversation with one of your matches.',
          ),
          const SizedBox(height: AmoraSpacing.space8),
          for (final chat in _allChats.take(5))
            _ConversationSheetAction(
              chat: chat,
              onTap: () {
                Navigator.pop(context);
                _openConversation(chat);
              },
            ),
        ],
      ),
    );
  }

  void _showInboxMenu() {
    showAmoraBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InboxSheetHeader(
            title: 'Inbox view',
            supporting: 'Choose which supported conversations to show.',
          ),
          const SizedBox(height: AmoraSpacing.space8),
          for (final filter in ChatInboxFilter.values)
            ListTile(
              minTileHeight: 54,
              leading: Icon(
                filter == _filter
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: filter == _filter
                    ? AppColors.secondary
                    : AppColors.primary,
              ),
              title: Text(
                _filterLabel(filter),
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() => _filter = filter);
              },
            ),
        ],
      ),
    );
  }

  void _showConversationActions(DummyConversation chat) {
    showAmoraBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InboxSheetHeader(
            title: chat.user.name,
            supporting: chat.lastMessage,
          ),
          const SizedBox(height: AmoraSpacing.space8),
          ListTile(
            minTileHeight: 54,
            leading: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
            ),
            title: const Text('Open conversation'),
            onTap: () {
              Navigator.pop(context);
              _openConversation(chat);
            },
          ),
          ListTile(
            minTileHeight: 54,
            leading: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primary,
            ),
            title: const Text('View profile'),
            onTap: () {
              Navigator.pop(context);
              _openProfile();
            },
          ),
        ],
      ),
    );
  }
}

enum ChatInboxFilter { all, unread, online }

String _filterLabel(ChatInboxFilter filter) => switch (filter) {
  ChatInboxFilter.all => 'All',
  ChatInboxFilter.unread => 'Unread',
  ChatInboxFilter.online => 'Online',
};

class ChatsAppBar extends StatelessWidget {
  const ChatsAppBar({
    super.key,
    required this.unreadCount,
    required this.onSearch,
    required this.onCompose,
    required this.onMore,
  });

  final int unreadCount;
  final VoidCallback onSearch;
  final VoidCallback onCompose;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.secondary.withValues(alpha: .18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .06),
            blurRadius: 18,
            spreadRadius: -7,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Chats',
              maxLines: 1,
              style: AmoraTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
          ),
          if (unreadCount > 0)
            Semantics(
              label: '$unreadCount unread messages',
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: AmoraRadius.pillBorder,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AmoraSpacing.space12,
                    vertical: AmoraSpacing.space4,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: AmoraTextStyles.labelSmall.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
          _InboxIconButton(
            tooltip: 'Search chats',
            icon: Icons.search_rounded,
            onPressed: onSearch,
          ),
          _InboxIconButton(
            tooltip: 'Compose message',
            icon: Icons.edit_square,
            onPressed: onCompose,
          ),
          _InboxIconButton(
            tooltip: 'More',
            icon: Icons.more_horiz_rounded,
            onPressed: onMore,
          ),
        ],
      ),
    );
  }
}

class _InboxIconButton extends StatelessWidget {
  const _InboxIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: SizedBox.square(
        dimension: 44,
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
          icon: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _InboxSheetHeader extends StatelessWidget {
  const _InboxSheetHeader({required this.title, required this.supporting});

  final String title;
  final String supporting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            supporting,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.text.withValues(alpha: .68),
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationSheetAction extends StatelessWidget {
  const _ConversationSheetAction({required this.chat, required this.onTap});

  final DummyConversation chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 62,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      onTap: onTap,
      leading: ConversationAvatar(
        profile: chat.user,
        online: chat.online,
        radius: 23,
      ),
      title: Text(
        chat.user.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.text.withValues(alpha: .64),
          fontSize: 13,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.primary,
      ),
    );
  }
}

class ChatSearchField extends StatefulWidget {
  const ChatSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<ChatSearchField> createState() => _ChatSearchFieldState();
}

class _ChatSearchFieldState extends State<ChatSearchField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant ChatSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    oldWidget.focusNode.removeListener(_onFocusChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    return AnimatedContainer(
      key: const ValueKey('chats-search-container'),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: focused
              ? AppColors.secondary
              : AppColors.secondary.withValues(alpha: .24),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: focused ? .08 : .05),
            blurRadius: focused ? 20 : 16,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
          if (focused)
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: .14),
              blurRadius: 18,
              spreadRadius: -5,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: TextField(
          key: const ValueKey('chats-search-field'),
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.search,
          cursorColor: AppColors.secondary,
          style: AmoraTextStyles.bodyLarge.copyWith(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search chats...',
            hintFadeDuration: const Duration(milliseconds: 200),
            hintStyle: AmoraTextStyles.bodyLarge.copyWith(
              color: AppColors.text.withValues(alpha: .56),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 50,
              minHeight: 54,
            ),
            suffixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: widget.hasQuery
                  ? Center(
                      key: const ValueKey('chats-search-clear-visible'),
                      child: Tooltip(
                        message: 'Clear search',
                        child: Material(
                          key: const ValueKey('chats-search-clear'),
                          color: AppColors.tertiary.withValues(alpha: .34),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: widget.onClear,
                            customBorder: const CircleBorder(),
                            child: const SizedBox.square(
                              dimension: 32,
                              child: Icon(
                                Icons.close_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('chats-search-clear-hidden'),
                    ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 54,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }
}

class ActiveMatchesSection extends StatelessWidget {
  const ActiveMatchesSection({
    super.key,
    required this.chats,
    required this.onOpen,
  });

  final List<DummyConversation> chats;
  final ValueChanged<DummyConversation> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AmoraSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ConversationSectionHeader(title: 'Active now'),
          SizedBox(
            key: const ValueKey('active-matches-list'),
            height: 96,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AmoraSpacing.space16,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: chats.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AmoraSpacing.space12),
              itemBuilder: (context, index) {
                final chat = chats[index];
                return ActiveMatchAvatar(
                  key: ValueKey('active-match-${chat.user.id}'),
                  chat: chat,
                  onTap: () => onOpen(chat),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveMatchAvatar extends StatelessWidget {
  const ActiveMatchAvatar({super.key, required this.chat, required this.onTap});

  final DummyConversation chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstName = chat.user.name.trim().split(RegExp(r'\s+')).first;
    return Semantics(
      button: true,
      label: 'Open chat with $firstName, online now',
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AmoraRadius.large),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ConversationAvatar(
                  profile: chat.user,
                  online: chat.online,
                  radius: 28,
                ),
                const SizedBox(height: AmoraSpacing.space8),
                Text(
                  firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AmoraTextStyles.labelSmall.copyWith(
                    color: AppColors.textNeutral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatFilterBar extends StatelessWidget {
  const ChatFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ChatInboxFilter selected;
  final ValueChanged<ChatInboxFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('chats-filter-bar'),
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ChatInboxFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AmoraSpacing.space8),
        itemBuilder: (context, index) {
          final filter = ChatInboxFilter.values[index];
          return _ChatFilterChip(
            filter: filter,
            selected: filter == selected,
            onTap: () => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _ChatFilterChip extends StatelessWidget {
  const _ChatFilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final ChatInboxFilter filter;
  final bool selected;
  final VoidCallback onTap;

  String get _label => _filterLabel(filter);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: AppColors.surface,
        borderRadius: AmoraRadius.pillBorder,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('chat-filter-${_label.toLowerCase()}'),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: AmoraSpacing.space16,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: AmoraRadius.pillBorder,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.tertiary,
              ),
            ),
            child: Text(
              _label,
              style: AmoraTextStyles.labelMedium.copyWith(
                color: selected ? AppColors.surface : AppColors.textNeutral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ConversationSectionHeader extends StatelessWidget {
  const ConversationSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AmoraSpacing.space16,
        AmoraSpacing.space8,
        AmoraSpacing.space16,
        AmoraSpacing.space8,
      ),
      child: Text(
        title,
        style: AmoraTextStyles.titleSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class ConversationTile extends StatefulWidget {
  const ConversationTile({
    super.key,
    required this.chat,
    required this.onOpen,
    required this.onOpenProfile,
    required this.onLongPress,
  });

  final DummyConversation chat;
  final VoidCallback onOpen;
  final VoidCallback onOpenProfile;
  final VoidCallback onLongPress;

  @override
  State<ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<ConversationTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final unread = chat.unread > 0;
    final highlighted = _hovered || _focused;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): widget.onOpen,
      },
      child: FocusableActionDetector(
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: Semantics(
          button: true,
          label:
              '${chat.user.name}, ${unread ? '${chat.unread} unread messages, ' : ''}${chat.lastMessage}, ${chat.time}',
          child: Material(
            color: highlighted
                ? AppColors.tertiary.withValues(alpha: .24)
                : unread
                ? AppColors.surface
                : AppColors.background,
            child: InkWell(
              onTap: widget.onOpen,
              onLongPress: widget.onLongPress,
              focusColor: AppColors.tertiary.withValues(alpha: .28),
              hoverColor: AppColors.tertiary.withValues(alpha: .24),
              child: Container(
                height: 82,
                padding: const EdgeInsets.symmetric(
                  horizontal: AmoraSpacing.space16,
                  vertical: 9,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.tertiary.withValues(alpha: .46),
                      ),
                      left: highlighted || unread
                          ? const BorderSide(
                              color: AppColors.secondary,
                              width: 2.5,
                            )
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Open ${chat.user.name} profile',
                        child: GestureDetector(
                          onTap: widget.onOpenProfile,
                          child: ConversationAvatar(
                            profile: chat.user,
                            online: chat.online,
                            radius: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: AmoraSpacing.space12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    chat.user.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AmoraTextStyles.titleMedium.copyWith(
                                      color: AppColors.text,
                                      fontWeight: unread
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AmoraSpacing.space8),
                                Text(
                                  chat.time,
                                  maxLines: 1,
                                  style: AmoraTextStyles.labelSmall.copyWith(
                                    color: unread
                                        ? AppColors.secondary
                                        : AppColors.text.withValues(alpha: .56),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AmoraSpacing.space4),
                            Row(
                              children: [
                                Expanded(
                                  child: MessagePreview(
                                    message: chat.lastMessage,
                                    unread: unread,
                                  ),
                                ),
                                if (unread) ...[
                                  const SizedBox(width: AmoraSpacing.space8),
                                  UnreadCountBadge(count: chat.unread),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ConversationAvatar extends StatelessWidget {
  const ConversationAvatar({
    super.key,
    required this.profile,
    required this.online,
    this.radius = 28,
  });

  final DummyProfile profile;
  final bool online;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ChatPresenceAvatar(profile: profile, radius: radius, online: online);
  }
}

class MessagePreview extends StatelessWidget {
  const MessagePreview({
    super.key,
    required this.message,
    required this.unread,
  });

  final String message;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final safeMessage = message.trim().isEmpty ? 'New message' : message.trim();
    return Text(
      safeMessage,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AmoraTextStyles.bodyMedium.copyWith(
        color: AppColors.textNeutral.withValues(alpha: unread ? .88 : .62),
        fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}

class UnreadCountBadge extends StatelessWidget {
  const UnreadCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count unread messages',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AmoraSpacing.space4),
        decoration: const BoxDecoration(
          color: AppColors.secondary,
          shape: BoxShape.circle,
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: AmoraTextStyles.labelSmall.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class ChatsEmptyState extends StatelessWidget {
  const ChatsEmptyState({super.key, required this.onDiscover});

  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return _ChatsStateLayout(
      icon: Icons.forum_outlined,
      title: 'Start a meaningful conversation',
      description: 'Your matches and messages will appear here.',
      actionLabel: 'Discover people',
      onAction: onDiscover,
    );
  }
}

class ChatsSearchEmptyState extends StatelessWidget {
  const ChatsSearchEmptyState({
    super.key,
    required this.hasQuery,
    required this.onClear,
  });

  final bool hasQuery;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _ChatsStateLayout(
      icon: hasQuery ? Icons.search_off_rounded : Icons.filter_alt_off_rounded,
      title: hasQuery ? 'No chats found' : 'No chats in this filter',
      description: hasQuery
          ? 'Try another name or keyword.'
          : 'Choose All to see every conversation.',
      actionLabel: hasQuery ? 'Clear search' : 'Show all chats',
      onAction: onClear,
    );
  }
}

class ChatsErrorState extends StatelessWidget {
  const ChatsErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ChatsStateLayout(
      icon: Icons.error_outline_rounded,
      title: 'Couldn’t load chats',
      description: 'Check your connection and try again.',
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}

class OfflineChatsBanner extends StatelessWidget {
  const OfflineChatsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.tertiary.withValues(alpha: .42),
          border: Border(
            bottom: BorderSide(
              color: AppColors.secondary.withValues(alpha: .48),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AmoraSpacing.space16,
            vertical: AmoraSpacing.space8,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AmoraSpacing.space8),
              Expanded(
                child: Text(
                  'You’re offline. Recent chats are still available.',
                  style: AmoraTextStyles.bodySmall.copyWith(
                    color: AppColors.textNeutral,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatsSkeleton extends StatelessWidget {
  const ChatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListView.builder(
        key: const ValueKey('chats-skeleton'),
        itemCount: 7,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AmoraSpacing.space16,
              vertical: AmoraSpacing.space12,
            ),
            child: Row(
              children: [
                const _SkeletonShape(width: 56, height: 56, circular: true),
                const SizedBox(width: AmoraSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(
                        widthFactor: .44 + (index.isEven ? .1 : 0),
                        child: const _SkeletonShape(height: 14),
                      ),
                      const SizedBox(height: AmoraSpacing.space8),
                      const FractionallySizedBox(
                        widthFactor: .78,
                        child: _SkeletonShape(height: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AmoraSpacing.space12),
                const _SkeletonShape(width: 28, height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonShape extends StatelessWidget {
  const _SkeletonShape({
    this.width,
    required this.height,
    this.circular = false,
  });

  final double? width;
  final double height;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: .42),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(height / 2),
      ),
    );
  }
}

class _ChatsStateLayout extends StatelessWidget {
  const _ChatsStateLayout({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AmoraSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: .42),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 72,
                child: Icon(icon, color: AppColors.primary, size: 34),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AmoraTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.textNeutral.withValues(alpha: .66),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                minimumSize: const Size(160, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

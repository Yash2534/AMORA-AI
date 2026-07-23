import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_search_bar.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class EventGroupChatScreen extends StatefulWidget {
  const EventGroupChatScreen({super.key});

  static const routeName = '/event-group-chat';

  @override
  State<EventGroupChatScreen> createState() => _EventGroupChatScreenState();
}

class _EventGroupChatScreenState extends State<EventGroupChatScreen> {
  final _controller = TextEditingController();
  final _search = TextEditingController();
  final List<String> _messages = [
    'AMORA Host: Welcome to Coffee Match Meetup. Keep it warm and respectful.',
    'Kavya: Looking forward to meeting everyone.',
    'Aarav: Is parking available near the venue?',
  ];
  String _query = '';
  bool _pollYes = false;

  @override
  void dispose() {
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages
        .where(
          (message) => message.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: _Header(onBack: () => Navigator.of(context).maybePop()),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    _CountdownBanner(),
                    const SizedBox(height: 12),
                    _SearchField(
                      controller: _search,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 12),
                    const _PinnedMessage(),
                    const SizedBox(height: 12),
                    _MembersList(),
                    const SizedBox(height: 12),
                    _SharedPhotos(),
                    const SizedBox(height: 12),
                    _PollCard(
                      voted: _pollYes,
                      onVote: () => setState(() => _pollYes = !_pollYes),
                    ),
                    const SizedBox(height: 12),
                    const _ReminderCard(),
                    const SizedBox(height: 12),
                    for (final message in messages)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MessageCard(text: message),
                      ),
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Kavya is typing...',
                        style: AmoraTextStyles.labelMedium.copyWith(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _Composer(controller: _controller, onSend: _send),
            ],
          ),
        ),
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return _snack('Type a message first');
    setState(() {
      _messages.add('You: $text');
      _controller.clear();
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        onPressed: onBack,
        icon: const Icon(AmoraIcons.back),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Group Chat',
              style: TextStyle(
                color: AppColors.deepWine,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Verified attendees and host announcements',
              style: TextStyle(
                color: AppColors.textGray,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const Chip(
        avatar: Icon(Icons.verified_rounded, size: 16),
        label: Text('Host'),
      ),
    ],
  );
}

class _CountdownBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PremiumCard(
    color: AppColors.lavenderBackground,
    child: const Row(
      children: [
        Icon(Icons.timer_rounded, color: AppColors.primaryPurple),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Event starts in 2 days, 6 hours',
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => AmoraSearchBar(
    controller: controller,
    onChanged: onChanged,
    hintText: 'Search group chat',
  );
}

class _PinnedMessage extends StatelessWidget {
  const _PinnedMessage();
  @override
  Widget build(BuildContext context) => const PremiumCard(
    child: Row(
      children: [
        Icon(Icons.push_pin_rounded, color: AppColors.premiumGold),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Pinned: Entry opens at 5:45 PM. Carry ID for verified check-in.',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}

class _MembersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 82,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _members.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final profile = ImageRepository.profileByName(_members[index]);
        return Column(
          children: [
            PremiumAvatar(
              imageUrl: profile.imageUrl,
              fallbackAsset: profile.fallbackAsset,
              initials: profile.initials,
              radius: 26,
              online: true,
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 64,
              child: Text(
                profile.name.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _SharedPhotos extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 92,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final event = ImageRepository.events[index];
        return PremiumAssetImage(
          imageUrl: event.imageUrl,
          fallbackAsset: event.fallbackAsset,
          initials: 'EV',
          width: 108,
          height: 92,
          borderRadius: BorderRadius.circular(22),
        );
      },
    ),
  );
}

class _PollCard extends StatelessWidget {
  const _PollCard({required this.voted, required this.onVote});
  final bool voted;
  final VoidCallback onVote;
  @override
  Widget build(BuildContext context) => PremiumCard(
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Poll: Coffee before icebreakers?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        FilledButton.tonal(
          onPressed: onVote,
          child: Text(voted ? 'Voted' : 'Vote'),
        ),
      ],
    ),
  );
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard();
  @override
  Widget build(BuildContext context) => const PremiumCard(
    child: Row(
      children: [
        Icon(Icons.event_available_rounded, color: AppColors.primaryPurple),
        SizedBox(width: 10),
        Expanded(child: Text('Reminder: Smart casual dress code.')),
      ],
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => PremiumCard(
    padding: const EdgeInsets.all(14),
    radius: 22,
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AmoraSpacing.space12),
    color: AppColors.surface,
    child: Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: controller,
            label: 'Message',
            hint: 'Message group',
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
          ),
        ),
        IconButton.filled(onPressed: onSend, icon: const Icon(AmoraIcons.send)),
      ],
    ),
  );
}

const _members = ['Aadhya', 'Kavya', 'Aarav', 'Riya', 'Ananya'];

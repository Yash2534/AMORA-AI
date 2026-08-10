import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amora_screen_title.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/data/event_repository.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:flutter/material.dart';

class EventGroupChatScreen extends StatefulWidget {
  const EventGroupChatScreen({super.key, this.event, this.repository});

  static const routeName = '/event-group-chat';

  final EventModel? event;
  final EventRepository? repository;

  @override
  State<EventGroupChatScreen> createState() => _EventGroupChatScreenState();
}

class _EventGroupChatScreenState extends State<EventGroupChatScreen> {
  final _controller = TextEditingController();
  final List<EventGroupMessage> _messages = [];
  EventModel? _event;
  bool _argumentsRead = false;
  bool _loading = true;
  bool _sending = false;
  Object? _error;

  EventRepository get _repository =>
      widget.repository ?? EventRepository.instance;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsRead) return;
    _argumentsRead = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (_event == null && arguments is EventModel) _event = arguments;
    _load();
  }

  @override
  void dispose() {
    _repository.disconnectEventChat();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final event = _event;
    if (event == null) {
      setState(() {
        _loading = false;
        _error = StateError('Event is required.');
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await _repository.groupMessages(event.id);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
        _loading = false;
      });
      await _repository.connectEventChat(event.id, _receiveRealtime);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  void _receiveRealtime(EventGroupMessage message) {
    if (!mounted || _messages.any((item) => item.id == message.id)) return;
    setState(() => _messages.add(message));
  }

  Future<void> _send() async {
    final event = _event;
    final text = _controller.text.trim();
    if (event == null || text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final message = await _repository.sendGroupMessage(event.id, text);
      if (!mounted) return;
      _controller.clear();
      if (!_messages.any((item) => item.id == message.id)) {
        setState(() => _messages.add(message));
      }
    } catch (error) {
      if (mounted) _snack(error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    AmoraHeaderBackButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: AmoraSpacing.space8),
                    Expanded(
                      child: AmoraScreenTitle(
                        title: _event?.title ?? 'Event Group Chat',
                        subtitle: 'Registered attendees and event host',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _body()),
              if (_event != null && _error == null)
                _Composer(
                  controller: _controller,
                  sending: _sending,
                  onSend: _send,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: PremiumCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 42),
                const SizedBox(height: 12),
                const Text('Event group chat is unavailable.'),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Try again')),
              ],
            ),
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text('No messages yet. Start the conversation.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      itemCount: _messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final message = _messages[index];
        return PremiumCard(
          padding: const EdgeInsets.all(14),
          radius: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      message.senderName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (message.verified)
                    const Icon(Icons.verified_rounded, size: 16),
                ],
              ),
              const SizedBox(height: 5),
              Text(message.text),
            ],
          ),
        );
      },
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
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
        IconButton.filled(
          onPressed: sending ? null : onSend,
          icon: sending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(AmoraIcons.send),
        ),
      ],
    ),
  );
}

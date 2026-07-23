import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_bottom_sheet.dart';
import 'package:amora_ai/core/widgets/amora_search_bar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/settings/presentation/widgets/settings_support_widgets.dart';
import 'package:flutter/material.dart';

class FaqSupportScreen extends StatefulWidget {
  const FaqSupportScreen({super.key});

  static const routeName = '/faq-support';

  @override
  State<FaqSupportScreen> createState() => _FaqSupportScreenState();
}

class _FaqSupportScreenState extends State<FaqSupportScreen> {
  final _searchController = TextEditingController();
  final List<_Ticket> _tickets = [
    const _Ticket(
      number: '#AMR-1024',
      category: 'Verification',
      status: 'In Review',
      eta: '2 hours',
    ),
  ];
  var _query = '';
  int? _expandedIndex;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Faq> get _filteredFaqs {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _faqs;
    return _faqs
        .where(
          (faq) =>
              faq.question.toLowerCase().contains(q) ||
              faq.answer.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _filteredFaqs;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.lavenderBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.navigationContentInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsHeader(
                    title: 'FAQ & Support',
                    subtitle:
                        'We are here to help you date safely and confidently.',
                    icon: Icons.support_agent_rounded,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 18),
                  AmoraSearchBar(
                    controller: _searchController,
                    onChanged: (value) => setState(() {
                      _query = value;
                      _expandedIndex = null;
                    }),
                    hintText: 'Search help topics...',
                    onClear: _query.isEmpty
                        ? null
                        : () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                  ),
                  const SizedBox(height: 18),
                  const _SectionLabel('Quick Help'),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: .95,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      SupportQuickCard(
                        label: 'Matching',
                        icon: Icons.favorite_rounded,
                        onTap: () => _setSearch('matching'),
                      ),
                      SupportQuickCard(
                        label: 'Payments',
                        icon: Icons.payment_rounded,
                        onTap: () => _setSearch('subscriptions'),
                      ),
                      SupportQuickCard(
                        label: 'Events',
                        icon: Icons.event_rounded,
                        onTap: () => _setSearch('events'),
                      ),
                      SupportQuickCard(
                        label: 'Safety',
                        icon: Icons.verified_user_rounded,
                        onTap: () => _setSearch('report'),
                      ),
                      SupportQuickCard(
                        label: 'Profile Verification',
                        icon: Icons.verified_rounded,
                        onTap: () => _setSearch('Blue Tick'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('FAQ'),
                  const SizedBox(height: 12),
                  if (faqs.isEmpty)
                    const PremiumCard(
                      child: Text(
                        'No help topics match this search.',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < faqs.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FAQAccordionTile(
                          question: faqs[i].question,
                          answer: faqs[i].answer,
                          expanded: _expandedIndex == i,
                          onTap: () => setState(
                            () =>
                                _expandedIndex = _expandedIndex == i ? null : i,
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                  const _SectionLabel('Contact Support'),
                  const SizedBox(height: 12),
                  SettingsSectionCard(
                    title: 'Support Channels',
                    children: [
                      SettingsTile(
                        icon: Icons.chat_rounded,
                        title: 'WhatsApp Support',
                        subtitle: 'Chat with AMORA support.',
                        onTap: () => showSettingsSnack(
                          context,
                          'Priority chat request queued for AMORA support',
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.email_rounded,
                        title: 'Email Support',
                        subtitle: 'Send details to the support desk.',
                        onTap: () => showSettingsSnack(
                          context,
                          'Email support request prepared',
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.call_rounded,
                        title: 'Call Request',
                        subtitle: 'Ask for a callback from AMORA.',
                        onTap: () => showSettingsSnack(
                          context,
                          'Call request submitted',
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.add_task_rounded,
                        title: 'Create Ticket',
                        subtitle: 'Track a private support request.',
                        onTap: _showTicketSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _SectionLabel('Ticket Status Tracker'),
                  const SizedBox(height: 12),
                  for (final ticket in _tickets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TicketStatusCard(
                        ticketNumber: 'Ticket ${ticket.number}',
                        category: ticket.category,
                        status: ticket.status,
                        eta: ticket.eta,
                      ),
                    ),
                  AppPrimaryButton(
                    label: 'Create Ticket',
                    icon: Icons.add_rounded,
                    onPressed: _showTicketSheet,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setSearch(String value) {
    _searchController.text = value;
    setState(() {
      _query = value;
      _expandedIndex = null;
    });
  }

  void _showTicketSheet() {
    var category = 'Verification';
    final messageController = TextEditingController();
    showAmoraBottomSheet<void>(
      context: context,
      child: Builder(
        builder: (context) {
          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Support Ticket',
                        style: AmoraTextStyles.titleLarge.copyWith(
                          color: AppColors.deepWine,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AmoraSpacing.space16),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Verification',
                            child: Text('Verification'),
                          ),
                          DropdownMenuItem(
                            value: 'Payments',
                            child: Text('Payments'),
                          ),
                          DropdownMenuItem(
                            value: 'Safety',
                            child: Text('Safety'),
                          ),
                          DropdownMenuItem(
                            value: 'Events',
                            child: Text('Events'),
                          ),
                        ],
                        onChanged: (value) =>
                            setSheetState(() => category = value ?? category),
                      ),
                      const SizedBox(height: AmoraSpacing.space12),
                      AppTextField(
                        controller: messageController,
                        label: 'Message',
                        hint: 'Tell us what happened',
                        minLines: 3,
                        maxLines: 5,
                      ),
                      const SizedBox(height: AmoraSpacing.space12),
                      AppPrimaryButton(
                        label: 'Attach screenshot',
                        icon: AmoraIcons.attachment,
                        variant: AppPrimaryButtonVariant.outlined,
                        onPressed: () => showSettingsSnack(
                          context,
                          'Screenshot attachment selected',
                        ),
                      ),
                      const SizedBox(height: AmoraSpacing.space16),
                      AppPrimaryButton(
                        label: 'Submit Ticket',
                        icon: AmoraIcons.send,
                        onPressed: () {
                          final message = messageController.text.trim();
                          if (message.isEmpty) {
                            showSettingsSnack(
                              context,
                              'Please enter a message',
                            );
                            return;
                          }
                          setState(() {
                            _tickets.insert(
                              0,
                              _Ticket(
                                number: '#AMR-${1024 + _tickets.length}',
                                category: category,
                                status: 'In Review',
                                eta: '2 hours',
                              ),
                            );
                          });
                          Navigator.pop(context);
                          showSettingsSnack(
                            context,
                            'Support ticket submitted',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.deepWine,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _Faq {
  const _Faq(this.question, this.answer);

  final String question;
  final String answer;
}

class _Ticket {
  const _Ticket({
    required this.number,
    required this.category,
    required this.status,
    required this.eta,
  });

  final String number;
  final String category;
  final String status;
  final String eta;
}

const _faqs = [
  _Faq(
    'How does AMORA AI compatibility score work?',
    'It combines profile intent, interests, lifestyle preferences, and conversation signals to estimate match quality.',
  ),
  _Faq(
    'How do I get Blue Tick verified?',
    'Complete selfie and ID verification from Profile Settings. AMORA reviews trust signals before activating the badge.',
  ),
  _Faq(
    'How can I report or block someone?',
    'Open Safety & Privacy or the chat menu, choose report or block, and AMORA will guide you through a respectful safety flow.',
  ),
  _Faq(
    'How do event bookings work?',
    'Events are booked from the Events module with a ticket pass, venue details, and confirmation summary.',
  ),
  _Faq(
    'How do subscriptions and refunds work?',
    'Subscriptions are shown in the Premium module. Refunds are handled through support after payment integration.',
  ),
  _Faq(
    'How do I delete my account?',
    'Use Safety & Privacy, open Dangerous Zone, and type DELETE to submit a deletion request.',
  ),
];

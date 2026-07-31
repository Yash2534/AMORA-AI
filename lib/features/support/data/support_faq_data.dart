import 'package:flutter/material.dart';

abstract final class SupportContact {
  static const email = 'support@amora.ai';
  static const subject = 'AMORAA Support Request';
  static const body = '''Hi AMORAA Support,

I need help with:

Account email:
Issue:
Steps already tried:

Thank you.''';
}

enum FaqCategory {
  all('All', Icons.auto_awesome_rounded),
  account('Account', Icons.person_rounded),
  profile('Profile', Icons.badge_rounded),
  matching('Matching', Icons.favorite_rounded),
  chats('Chats', Icons.chat_bubble_rounded),
  safety('Safety', Icons.shield_rounded),
  payments('Payments', Icons.payment_rounded),
  events('Events', Icons.calendar_month_rounded),
  privacy('Privacy', Icons.privacy_tip_rounded);

  const FaqCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

class SupportFaqItem {
  const SupportFaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    this.popular = false,
  });

  final String id;
  final FaqCategory category;
  final String question;
  final String answer;
  final bool popular;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return question.toLowerCase().contains(normalized) ||
        answer.toLowerCase().contains(normalized) ||
        category.label.toLowerCase().contains(normalized);
  }
}

const supportFaqs = <SupportFaqItem>[
  SupportFaqItem(
    id: 'compatibility-score',
    category: FaqCategory.matching,
    question: 'How does AMORAA compatibility work?',
    answer:
        'Compatibility combines profile intent, interests, lifestyle '
        'preferences, and conversation signals to help surface relevant '
        'matches.',
    popular: true,
  ),
  SupportFaqItem(
    id: 'blue-tick',
    category: FaqCategory.profile,
    question: 'How do I get Blue Tick verified?',
    answer:
        'Open Profile Settings and complete the available selfie and identity '
        'verification steps. Your badge reflects the verification state '
        'already shown in your profile.',
    popular: true,
  ),
  SupportFaqItem(
    id: 'report-block',
    category: FaqCategory.safety,
    question: 'How can I report or block someone?',
    answer:
        'Open Safety & Privacy or the conversation menu, then choose the '
        'available report or block action. Use the safety flow whenever a '
        'conversation or profile makes you uncomfortable.',
    popular: true,
  ),
  SupportFaqItem(
    id: 'join-event',
    category: FaqCategory.events,
    question: 'How do I join an AMORAA event?',
    answer:
        'Open Events, choose a gathering, and use its current Join, Request, '
        'or Waitlist action. Joined gatherings appear in My Events.',
    popular: true,
  ),
  SupportFaqItem(
    id: 'event-change',
    category: FaqCategory.events,
    question: 'Where can I review or leave an event?',
    answer:
        'Open My Events from the Events page to review your current status. '
        'When leaving is supported, the event card provides that action.',
  ),
  SupportFaqItem(
    id: 'subscription',
    category: FaqCategory.payments,
    question: 'Where can I manage my subscription?',
    answer:
        'Open Profile Settings and choose Manage Subscription to review the '
        'plans and membership controls currently available to your account.',
  ),
  SupportFaqItem(
    id: 'delete-account',
    category: FaqCategory.account,
    question: 'How do I delete my account?',
    answer:
        'Open Safety & Privacy and use the account deletion control in the '
        'danger zone. Review the confirmation carefully before continuing.',
  ),
  SupportFaqItem(
    id: 'edit-profile',
    category: FaqCategory.profile,
    question: 'How do I update my profile?',
    answer:
        'Open Profile and choose Edit Profile to update supported personal '
        'details, photos, prompts, interests, and lifestyle information.',
  ),
  SupportFaqItem(
    id: 'message-status',
    category: FaqCategory.chats,
    question: 'What do message status indicators mean?',
    answer:
        'Status indicators use the existing messaging state to show whether a '
        'message is sending, sent, delivered, read, or failed.',
  ),
  SupportFaqItem(
    id: 'chat-safety',
    category: FaqCategory.chats,
    question: 'How do I manage an uncomfortable conversation?',
    answer:
        'Use the conversation menu for the available mute, block, or report '
        'actions, and visit Safety & Privacy for additional controls.',
  ),
  SupportFaqItem(
    id: 'privacy-visibility',
    category: FaqCategory.privacy,
    question: 'Where are my visibility controls?',
    answer:
        'Profile Settings contains the visibility controls currently '
        'supported by AMORAA, including online status and profile visibility.',
  ),
  SupportFaqItem(
    id: 'match-preferences',
    category: FaqCategory.matching,
    question: 'How do I refine who I discover?',
    answer:
        'Use the available discovery filters and dating preferences. Changes '
        'apply through the existing matching and preference behavior.',
  ),
];

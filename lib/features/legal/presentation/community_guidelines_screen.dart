import 'package:amora_ai/features/legal/presentation/legal_document_screen.dart';
import 'package:flutter/material.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  static const routeName = '/community-guidelines';

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Community Guidelines',
      updated: 'Effective 31 July 2026',
      introduction:
          'These guidelines explain the respectful, authentic, and safety-first '
          'behavior expected across the AMORAA community.',
      sections: [
        LegalSection(
          'Be authentic',
          'Use current photos and accurate information. Do not impersonate '
              'another person, misrepresent your intentions, or operate deceptive '
              'or fraudulent accounts.',
        ),
        LegalSection(
          'Treat people with respect',
          'Harassment, threats, hate, coercion, sexual exploitation, and '
              'discrimination are not welcome. Respect boundaries and stop '
              'contact when another member asks you to.',
        ),
        LegalSection(
          'Keep conversations safe',
          'Never pressure someone to share private information, intimate '
              'content, money, or account credentials. Move at a pace that feels '
              'comfortable to everyone involved.',
        ),
        LegalSection(
          'Protect the community',
          'Do not post illegal, exploitative, violent, or unsolicited '
              'commercial content. Content that endangers minors or vulnerable '
              'people is prohibited.',
        ),
        LegalSection(
          'Report concerns',
          'Use AMORAA reporting controls when a profile, message, or offline '
              'interaction raises a safety concern. Blocking remains private, and '
              'urgent danger should be reported to local emergency services.',
        ),
        LegalSection(
          'How enforcement works',
          'AMORAA may review reports and restrict features or remove access '
              'when necessary to protect members, comply with law, or enforce '
              'these community standards.',
        ),
      ],
    );
  }
}

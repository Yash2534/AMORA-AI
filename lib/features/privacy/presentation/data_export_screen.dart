import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  static const routeName = '/data-export';

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  bool _requested = false;
  bool _ready = false;
  final Set<String> _sections = {'Profile data', 'Match history'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AmoraAppBar(
        title: 'Data Export',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AmoraSpacing.space16,
              AmoraSpacing.space20,
              AmoraSpacing.space20,
              AmoraSpacing.navigationContentInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PremiumCard(
                  color: AppColors.lavenderBackground,
                  child: Text(
                    'DPDP-ready export controls for account data. This local UI prepares future backend request and secure download workflows.',
                    style: TextStyle(
                      color: AppColors.deepWine,
                      height: 1.35,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final section in _allSections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PremiumCard(
                      padding: const EdgeInsets.all(4),
                      child: CheckboxListTile(
                        value: _sections.contains(section),
                        onChanged: (value) => setState(() {
                          value == true
                              ? _sections.add(section)
                              : _sections.remove(section);
                        }),
                        title: Text(
                          section,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ready
                            ? 'Export ready'
                            : _requested
                            ? 'Preparing export'
                            : 'No active export',
                        style: const TextStyle(
                          color: AppColors.deepWine,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _ready
                            ? 1
                            : _requested
                            ? .62
                            : 0,
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: _ready
                      ? 'Download export'
                      : _requested
                      ? 'Prepare export'
                      : 'Request export',
                  icon: _ready
                      ? Icons.download_rounded
                      : Icons.file_download_rounded,
                  onPressed: _handleRequest,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleRequest() {
    if (_ready) {
      _snack('Your export is ready to download');
      return;
    }
    setState(() {
      if (_requested) {
        _ready = true;
      } else {
        _requested = true;
      }
    });
    _snack(_ready ? 'Export is ready' : 'Export request submitted');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

const _allSections = [
  'Profile data',
  'Chat history',
  'Payments',
  'Events',
  'Match history',
];

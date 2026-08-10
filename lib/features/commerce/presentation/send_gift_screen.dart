import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amora_screen_title.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/monetization/data/monetization_repository.dart';
import 'package:amora_ai/features/monetization/domain/monetization_models.dart';
import 'package:flutter/material.dart';

class SendGiftScreen extends StatefulWidget {
  const SendGiftScreen({super.key});
  static const routeName = '/send-gift';
  @override
  State<SendGiftScreen> createState() => _SendGiftScreenState();
}

class _SendGiftScreenState extends State<SendGiftScreen> {
  List<GiftProduct>? _gifts;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final gifts = await MonetizationRepository.instance.gifts();
      if (mounted) setState(() => _gifts = gifts);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gift catalog could not be loaded.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              AmoraSpacing.navigationContentInset,
            ),
            children: [
              Row(
                children: [
                  AmoraHeaderBackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: AmoraScreenTitle(title: 'Send a Gift')),
                ],
              ),
              const SizedBox(height: 20),
              if (_gifts == null && _error == null)
                const Center(child: CircularProgressIndicator()),
              if (_error != null) PremiumCard(child: Text(_error!)),
              if (_gifts != null) ...[
                for (final gift in _gifts!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PremiumCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(gift.name),
                        subtitle: Text(gift.description ?? gift.type),
                        trailing: Text('${gift.priceCredits} credits'),
                      ),
                    ),
                  ),
                const PremiumCard(
                  child: Text(
                    'Choose Send Gift from a profile to securely select the recipient.',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

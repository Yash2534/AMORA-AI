import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class OfflineModeScreen extends StatefulWidget {
  const OfflineModeScreen({super.key});

  static const routeName = '/offline-mode';

  @override
  State<OfflineModeScreen> createState() => _OfflineModeScreenState();
}

class _OfflineModeScreenState extends State<OfflineModeScreen> {
  bool _downloads = true;
  bool _cachedChats = true;
  bool _profiles = true;
  bool _events = true;
  bool _photos = false;
  bool _autoCache = true;
  double _cacheSize = 420;
  int _syncPending = 7;

  @override
  Widget build(BuildContext context) {
    final usage = (_cacheSize / 1024).clamp(0, 1).toDouble();
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AmoraSpacing.space20,
              AmoraSpacing.space20,
              AmoraSpacing.space20,
              AmoraSpacing.navigationContentInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Header(),
                const SizedBox(height: 18),
                PremiumCard(
                  color: AppColors.lavenderBackground,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Storage Usage',
                        style: TextStyle(
                          color: AppColors.deepWine,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: usage, minHeight: 9),
                      const SizedBox(height: 8),
                      Text('${_cacheSize.round()} MB cached locally'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PremiumCard(
                  child: Column(
                    children: [
                      _Toggle(
                        'Offline Downloads',
                        _downloads,
                        (value) => setState(() => _downloads = value),
                      ),
                      _Toggle(
                        'Cached Chats',
                        _cachedChats,
                        (value) => setState(() => _cachedChats = value),
                      ),
                      _Toggle(
                        'Saved Profiles',
                        _profiles,
                        (value) => setState(() => _profiles = value),
                      ),
                      _Toggle(
                        'Saved Events',
                        _events,
                        (value) => setState(() => _events = value),
                      ),
                      _Toggle(
                        'Downloaded Photos',
                        _photos,
                        (value) => setState(() => _photos = value),
                      ),
                      _Toggle(
                        'Auto Cache',
                        _autoCache,
                        (value) => setState(() => _autoCache = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cache Size ${_cacheSize.round()} MB',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Slider(
                        value: _cacheSize,
                        min: 100,
                        max: 1024,
                        divisions: 18,
                        onChanged: (value) =>
                            setState(() => _cacheSize = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PremiumCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sync_rounded,
                        color: AppColors.primaryPurple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$_syncPending sync items pending',
                          style: const TextStyle(
                            color: AppColors.deepWine,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      AppPrimaryButton(
                        label: 'Sync',
                        size: AmoraButtonSize.compact,
                        fullWidth: false,
                        variant: AppPrimaryButtonVariant.text,
                        onPressed: () => setState(() => _syncPending = 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const PremiumCard(
                  child: Text(
                    'Offline availability: saved profiles, event passes, safety tips, and recent chats will stay available without network.',
                    style: TextStyle(
                      color: AppColors.textGray,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: 'Clear Cache',
                  icon: Icons.delete_sweep_rounded,
                  variant: AppPrimaryButtonVariant.outlined,
                  onPressed: () {
                    setState(() => _cacheSize = 0);
                    _snack('Cache cleared locally');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Text(
          'Offline Mode',
          style: TextStyle(
            color: AppColors.deepWine,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle(this.title, this.value, this.onChanged);
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
    value: value,
    onChanged: onChanged,
  );
}

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:flutter/material.dart';

typedef AccountReactivationCallback = Future<void> Function(String token);
typedef ReactivationCompletedCallback =
    Future<void> Function(BuildContext context);

class WelcomeBackReactivationScreen extends StatefulWidget {
  const WelcomeBackReactivationScreen({
    super.key,
    this.reactivationToken,
    this.reactivate,
    this.onReactivated,
  });

  static const routeName = '/welcome-back-reactivation';

  final String? reactivationToken;
  final AccountReactivationCallback? reactivate;
  final ReactivationCompletedCallback? onReactivated;

  @override
  State<WelcomeBackReactivationScreen> createState() =>
      _WelcomeBackReactivationScreenState();
}

class _WelcomeBackReactivationScreenState
    extends State<WelcomeBackReactivationScreen> {
  bool _submitting = false;
  String? _error;

  String get _token =>
      widget.reactivationToken ??
      (ModalRoute.of(context)?.settings.arguments as String? ?? '');

  Future<void> _activate() async {
    if (_submitting) return;
    if (_token.isEmpty) {
      setState(
        () => _error = 'Please sign in again to reactivate your account.',
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final reactivate = widget.reactivate;
      if (reactivate == null) {
        await AuthService.instance.reactivate(_token);
      } else {
        await reactivate(_token);
      }
      if (!mounted) return;
      final completed = widget.onReactivated;
      if (completed == null) {
        await AmoraSession.completeAuthentication(context);
      } else {
        await completed(context);
      }
      if (mounted) setState(() => _submitting = false);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.code == 'REACTIVATION_EXPIRED'
            ? 'Your reactivation session has expired. Please sign in again.'
            : error.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'We could not reactivate your account. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AmoraAuthShell(
      title: 'Welcome Back',
      subtitle: 'Your AMORAA account is currently deactivated.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AmoraSpacing.space20),
            decoration: BoxDecoration(
              color: AppColors.softBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 38,
                ),
                const SizedBox(height: AmoraSpacing.space12),
                Text(
                  'Your profile, matches, conversations, and preferences are still here.',
                  textAlign: TextAlign.center,
                  style: AmoraTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AmoraSpacing.space12),
            AuthInlineAlert(message: _error!),
          ],
          const SizedBox(height: AmoraSpacing.space20),
          AppPrimaryButton(
            key: const ValueKey('activate-account-button'),
            label: 'Activate Your Account',
            icon: Icons.refresh_rounded,
            isLoading: _submitting,
            onPressed: _submitting ? null : _activate,
          ),
        ],
      ),
    );
  }
}

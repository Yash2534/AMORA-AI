import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/features/auth/presentation/account_verification_screen.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/onboarding/presentation/profile_onboarding_flow.dart';
import 'package:amora_ai/features/monetization/data/monetization_repository.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:flutter/material.dart';
import 'dart:async';

typedef AuthenticatedAction = void Function();

class AmoraSession {
  AmoraSession._();

  static final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);
  static final ValueNotifier<AmoraUser?> user = ValueNotifier<AmoraUser?>(null);
  static final ValueNotifier<int> profileStrength = ValueNotifier<int>(20);
  static AuthenticatedAction? _pendingAction;

  static bool get isGuest => !isLoggedIn.value;
  static bool get isExploring => !isLoggedIn.value;
  static bool get hasPendingAction => _pendingAction != null;

  static String get authenticatedRecoveryRoute {
    final onboarding = LocalOnboardingRepository.instance.state;
    if (!onboarding.accountVerified) {
      return AccountVerificationScreen.routeName;
    }
    if (!onboarding.onboardingCompleted) {
      return ProfileOnboardingFlow.routeName;
    }
    return MainShell.routeName;
  }

  static void logIn() {
    isLoggedIn.value = true;
    user.value = AuthService.instance.currentUser;
    if (profileStrength.value < 20) profileStrength.value = 20;
  }

  static void logOut() {
    isLoggedIn.value = false;
    user.value = null;
    profileStrength.value = 20;
    _pendingAction = null;
    MonetizationRepository.instance.clearSessionState();
    LocalProfileRepository.instance.clearSessionProfile();
    ProfileRelationshipController.instance.clearSessionState();
    unawaited(AuthService.instance.logout());
  }

  static Future<void> restore() async {
    final restored = await AuthService.instance.restoreSession();
    isLoggedIn.value = restored;
    user.value = restored ? AuthService.instance.currentUser : null;
    if (restored) {
      try {
        await MonetizationRepository.instance.refreshMembership();
      } catch (_) {
        // Authentication remains valid; monetization screens expose retry UI.
      }
    } else {
      MonetizationRepository.instance.clearSessionState();
    }
  }

  static void completeProfileStep(int strength) {
    profileStrength.value = strength.clamp(20, 100);
  }

  static Future<void> requireAuth({
    required BuildContext context,
    required AuthenticatedAction onAuthenticated,
  }) async {
    if (isLoggedIn.value) {
      onAuthenticated();
      return;
    }

    _pendingAction = onAuthenticated;
    await showLoginRequiredSheet(context);
  }

  static Future<void> completeAuthentication(BuildContext context) async {
    logIn();
    LocalProfileRepository.instance.prepareForAuthenticatedUser();
    ProfileRelationshipController.instance.clearSessionState();
    try {
      await Future.wait<void>([
        LocalProfileRepository.instance.refreshFromServer(),
        ProfileRelationshipController.instance.refreshRemote(),
      ]);
    } catch (_) {
      // The destination screens expose retry/error state for remote data.
    }
    final action = _pendingAction;
    _pendingAction = null;

    if (action != null) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      await Future<void>.delayed(AmoraMotion.fast);
      action();
      return;
    }

    final route = LocalOnboardingRepository.instance.state.onboardingCompleted
        ? MainShell.routeName
        : ProfileOnboardingFlow.routeName;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }
}

Future<void> showLoginRequiredSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.transparent,
    sheetAnimationStyle: const AnimationStyle(
      duration: AmoraMotion.standard,
      reverseDuration: AmoraMotion.fast,
      curve: AmoraMotion.curve,
      reverseCurve: AmoraMotion.curve,
    ),
    builder: (sheetContext) {
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            22,
            12,
            22,
            22 + MediaQuery.viewPaddingOf(sheetContext).bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.borderGray,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.deepWine,
                  ),
                ),
                const SizedBox(height: 4),
                AspectRatio(
                  aspectRatio: 1.85,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PremiumAssetImage(
                          imageUrl: AppImages.profileAadhya,
                          fallbackAsset: AppImages.fallbackProfile,
                          initials: 'AM',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .46),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Explore freely. Sign in when you are ready to connect.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.surface,
                                    fontSize: 18,
                                    height: 1.16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Continue Your Journey',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.deepWine,
                    fontSize: 24,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to like profiles, start conversations, join events, and unlock your personalized AI matchmaking experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textGray,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                AppPrimaryButton(
                  label: 'Continue with Email',
                  icon: Icons.person_outline_rounded,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).pushNamed('/login');
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

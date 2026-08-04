import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/features/profile/domain/profile_completion_calculator.dart';
import 'package:flutter/material.dart';

class ProfileFormNavigationTargets {
  final Map<ProfileFormFieldId, GlobalKey> _keys = {
    for (final id in ProfileFormFieldId.values)
      id: GlobalKey(debugLabel: 'profile-field-${id.name}'),
  };

  final Map<ProfileFormFieldId, FocusNode> _focusNodes = {
    ProfileFormFieldId.name: FocusNode(debugLabel: 'profile-name-focus'),
    ProfileFormFieldId.occupation: FocusNode(
      debugLabel: 'profile-custom-occupation-focus',
    ),
    ProfileFormFieldId.bio: FocusNode(debugLabel: 'profile-bio-focus'),
    ProfileFormFieldId.profilePrompt: FocusNode(
      debugLabel: 'profile-prompt-focus',
    ),
  };

  GlobalKey keyFor(ProfileFormFieldId id) => _keys[id]!;

  FocusNode? focusNodeFor(ProfileFormFieldId id) => _focusNodes[id];

  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
  }
}

class ProfileFormTarget extends StatelessWidget {
  const ProfileFormTarget({
    super.key,
    required this.id,
    required this.targets,
    required this.highlighted,
    required this.label,
    required this.child,
  });

  final ProfileFormFieldId id;
  final ProfileFormNavigationTargets targets;
  final bool highlighted;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return KeyedSubtree(
      key: ValueKey('profile-target-${id.name}'),
      child: Semantics(
        container: true,
        liveRegion: highlighted,
        label: highlighted ? '$label, ready for editing' : label,
        child: AnimatedContainer(
          key: targets.keyFor(id),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.tertiary.withValues(alpha: .28)
                : AppColors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: highlighted ? AppColors.secondary : AppColors.transparent,
              width: 2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

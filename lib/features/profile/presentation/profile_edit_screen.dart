import 'package:amora_ai/features/profile/domain/profile_completion_calculator.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_form.dart';
import 'package:flutter/material.dart';

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key, this.initialField});

  final ProfileFormFieldId? initialField;

  static const routeName = '/edit-profile';

  @override
  Widget build(BuildContext context) {
    final routeArgument = ModalRoute.settingsOf(context)?.arguments;
    return AmoraaProfileForm(
      mode: ProfileFormMode.edit,
      initialField:
          initialField ??
          (routeArgument is ProfileFormFieldId ? routeArgument : null),
      onSaved: (context, profile) async {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile changes saved')));
      },
    );
  }
}

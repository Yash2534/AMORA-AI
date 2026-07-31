import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_form.dart';
import 'package:flutter/material.dart';

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  static const routeName = '/edit-profile';

  @override
  Widget build(BuildContext context) {
    return AmoraaProfileForm(
      mode: ProfileFormMode.edit,
      onSaved: (context, profile) async {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile changes saved')));
      },
    );
  }
}

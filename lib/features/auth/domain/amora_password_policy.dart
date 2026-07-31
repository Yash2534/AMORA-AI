abstract final class AmoraPasswordPolicy {
  static const minimumLength = 8;
  static const requirement = 'Use at least 8 characters.';

  static String? validateNewPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < minimumLength) return requirement;
    return null;
  }

  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }
}

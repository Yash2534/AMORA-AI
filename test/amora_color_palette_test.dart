import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the active AMORAA Premium Plum palette remains canonical', () {
    expect(AppColors.primary, const Color(0xFF713F62));
    expect(AppColors.primaryDark, const Color(0xFF4B1F45));
    expect(AppColors.primaryLight, const Color(0xFF8F5A88));
    expect(AppColors.secondary, const Color(0xFFE8D4E5));
    expect(AppColors.tertiary, const Color(0xFFF3DCEB));
    expect(AppColors.background, const Color(0xFFFEFCFF));
    expect(AppColors.surface, const Color(0xFFFFFFFF));
    expect(AppColors.textPrimary, const Color(0xFF35152F));
  });
}

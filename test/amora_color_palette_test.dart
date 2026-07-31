import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all active Dart UI uses only the approved AMORAA palette', () {
    const appColorsPath = 'lib/core/theme/app_colors.dart';
    const approvedHexValues = {
      '0xFF3D0B3F',
      '0xFFEC5FA8',
      '0xFFF4A9CE',
      '0xFFFDF1F7',
      '0xFFFFFFFF',
      '0xFF2B2B2B',
    };
    const approvedGradientLists = {
      'AppColors.secondary,AppColors.primary',
      'AppColors.secondary,AppColors.tertiary,AppColors.primary',
      'AppColors.background,AppColors.surface',
    };
    final violations = <String>[];
    final files =
        Directory('lib')
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/');
      final source = file.readAsStringSync();
      final lines = source.split('\n');

      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        final lineNumber = index + 1;

        for (final match in RegExp(
          r'\bColor\s*\(\s*(0x[0-9A-Fa-f]{8})\s*\)',
        ).allMatches(line)) {
          final value = _normalizeHex(match.group(1)!);
          final isApprovedDefinition =
              path == appColorsPath && approvedHexValues.contains(value);
          if (!isApprovedDefinition) {
            _addViolation(
              violations,
              path,
              lineNumber,
              match.group(0)!,
              'Replace with the matching semantic AppColors role.',
            );
          }
        }

        for (final match in RegExp(
          r'\bColors\.([A-Za-z_][A-Za-z0-9_]*)',
        ).allMatches(line)) {
          if (match.group(1) != 'transparent') {
            _addViolation(
              violations,
              path,
              lineNumber,
              match.group(0)!,
              'Use AppColors.primary, secondary, tertiary, background, '
              'surface, or text.',
            );
          }
        }

        _checkPattern(
          violations,
          path,
          lineNumber,
          line,
          RegExp(r'\bColor\.(?:fromARGB|fromRGBO)\s*\('),
          'Use an AppColors semantic role and derive alpha with withValues.',
        );
        _checkPattern(
          violations,
          path,
          lineNumber,
          line,
          RegExp(r'\bCupertinoColors\b'),
          'Use the corresponding AppColors semantic role.',
        );
        _checkPattern(
          violations,
          path,
          lineNumber,
          line,
          RegExp(r'\bMaterialColor\b'),
          'Use the explicit AMORAA ColorScheme and AppColors roles.',
        );
        _checkPattern(
          violations,
          path,
          lineNumber,
          line,
          RegExp(r'\bColorScheme\.fromSeed\b'),
          'Use AmoraTheme.colorScheme.',
        );
        _checkPattern(
          violations,
          path,
          lineNumber,
          line,
          RegExp(r'\bThemeData\.dark\b'),
          'Use AmoraTheme.light until an approved dark palette exists.',
        );
        _checkPattern(
          violations,
          path,
          lineNumber,
          line,
          RegExp(r'\.(?:withOpacity|withAlpha)\s*\('),
          'Derive alpha from AppColors with withValues(alpha: ...).',
        );
      }

      final rawDefinitions = RegExp(
        r'\bColor\s*\(\s*(0x[0-9A-Fa-f]{8})\s*\)',
      ).allMatches(source);
      if (path == appColorsPath) {
        final values = rawDefinitions
            .map((match) => _normalizeHex(match.group(1)!))
            .toList();
        if (values.length != approvedHexValues.length ||
            values.toSet().length != approvedHexValues.length ||
            !values.toSet().containsAll(approvedHexValues)) {
          violations.add(
            '$path:1 — palette definitions are not exactly the six approved '
            'values. Suggested replacement: retain each approved value once.',
          );
        }
      }

      final gradientPattern = RegExp(
        r'(?:Linear|Radial|Sweep)Gradient\s*\('
        r'[\s\S]*?colors\s*:\s*(?:const\s*)?\[([\s\S]*?)\]',
      );
      for (final match in gradientPattern.allMatches(source)) {
        final normalized = match
            .group(1)!
            .replaceAll(RegExp(r'\s+'), '')
            .replaceAll(RegExp(r',+$'), '');
        if (!approvedGradientLists.contains(normalized)) {
          _addViolation(
            violations,
            path,
            _lineNumberAt(source, match.start),
            '${match.group(0)!.split('\n').first} colors: [$normalized]',
            'Use [AppColors.secondary, AppColors.primary], '
                '[AppColors.secondary, AppColors.tertiary, '
                'AppColors.primary], or '
                '[AppColors.background, AppColors.surface].',
          );
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Unauthorized AMORAA palette usage found:\n${violations.join('\n')}',
    );
  });
}

void _checkPattern(
  List<String> violations,
  String path,
  int lineNumber,
  String line,
  RegExp pattern,
  String suggestion,
) {
  for (final match in pattern.allMatches(line)) {
    _addViolation(violations, path, lineNumber, match.group(0)!, suggestion);
  }
}

void _addViolation(
  List<String> violations,
  String path,
  int lineNumber,
  String expression,
  String suggestion,
) {
  violations.add(
    '$path:$lineNumber — unauthorized "$expression". '
    'Suggested replacement: $suggestion',
  );
}

int _lineNumberAt(String source, int offset) {
  return '\n'.allMatches(source.substring(0, offset)).length + 1;
}

String _normalizeHex(String value) {
  return value.toUpperCase().replaceFirst('0X', '0x');
}

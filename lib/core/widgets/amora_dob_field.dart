import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class AmoraDateOfBirth {
  static const minimumAge = 18;
  static const maximumAge = 100;

  static DateTime? parse(String? value) {
    final normalized = value?.replaceAll(' ', '').trim() ?? '';
    final parts = normalized.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final candidate = DateTime(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      return null;
    }
    return DateUtils.dateOnly(candidate);
  }

  static String format(DateTime value) {
    final date = DateUtils.dateOnly(value);
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year.toString().padLeft(4, '0')}';
  }

  static DateTime yearsAgo(DateTime from, int years) {
    final targetYear = from.year - years;
    final lastDay = DateTime(targetYear, from.month + 1, 0).day;
    return DateTime(targetYear, from.month, from.day.clamp(1, lastDay).toInt());
  }

  static String? validate(DateTime? value, {DateTime? now}) {
    if (value == null) return 'Select your date of birth';
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final date = DateUtils.dateOnly(value);
    if (date.isAfter(today)) return 'Date of birth cannot be in the future';
    if (date.isAfter(yearsAgo(today, minimumAge))) {
      return 'You must be at least $minimumAge years old';
    }
    if (date.isBefore(yearsAgo(today, maximumAge))) {
      return 'Enter a date within the last $maximumAge years';
    }
    return null;
  }

  static int? age(DateTime? value, {DateTime? now}) {
    if (validate(value, now: now) != null) return null;
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final date = DateUtils.dateOnly(value!);
    var result = today.year - date.year;
    if (today.month < date.month ||
        (today.month == date.month && today.day < date.day)) {
      result--;
    }
    return result;
  }
}

class AmoraDobField extends StatelessWidget {
  const AmoraDobField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.label = 'Date of birth',
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;
  final String label;

  @override
  Widget build(BuildContext context) {
    final display = value == null
        ? 'DD/MM/YYYY'
        : AmoraDateOfBirth.format(value!);
    return Semantics(
      button: true,
      label: value == null ? 'Select date of birth' : '$label, $display',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _pick(context),
        child: InputDecorator(
          isEmpty: false,
          decoration: InputDecoration(
            labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            errorText: errorText,
            prefixIcon: const Icon(Icons.calendar_month_rounded),
            suffixIcon: const Icon(Icons.expand_more_rounded),
          ),
          child: Text(
            display,
            maxLines: 1,
            style: AmoraTextStyles.bodyLarge.copyWith(
              color: value == null
                  ? Theme.of(context).colorScheme.outline
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = AmoraDateOfBirth.yearsAgo(
      today,
      AmoraDateOfBirth.maximumAge,
    );
    final lastDate = AmoraDateOfBirth.yearsAgo(
      today,
      AmoraDateOfBirth.minimumAge,
    );
    final candidate = value ?? AmoraDateOfBirth.yearsAgo(today, 24);
    final initialDate = candidate.isBefore(firstDate)
        ? firstDate
        : candidate.isAfter(lastDate)
        ? lastDate
        : candidate;

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select date of birth',
      fieldLabelText: 'Date of birth',
      fieldHintText: 'DD/MM/YYYY',
      errorFormatText: 'Use DD/MM/YYYY',
      errorInvalidText: 'Choose a valid date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (selected != null) onChanged(DateUtils.dateOnly(selected));
  }
}

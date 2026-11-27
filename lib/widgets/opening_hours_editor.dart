import 'package:flutter/material.dart';

import '../models/shop_profile.dart';
import '../theme/app_theme.dart';

const _dayNames = {
  1: 'จันทร์',
  2: 'อังคาร',
  3: 'พุธ',
  4: 'พฤหัสบดี',
  5: 'ศุกร์',
  6: 'เสาร์',
  7: 'อาทิตย์',
};

const _defaultHours = DayHours(openMinute: 9 * 60, closeMinute: 18 * 60);

String formatMinute(int minute) {
  final h = (minute ~/ 60).toString().padLeft(2, '0');
  final m = (minute % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

/// One row per weekday: a switch for open/closed and two time pickers.
class OpeningHoursEditor extends StatelessWidget {
  final OpeningHours value;
  final ValueChanged<OpeningHours> onChanged;

  const OpeningHoursEditor({
    super.key,
    required this.value,
    required this.onChanged,
  });

  void _setDay(int weekday, DayHours? hours) {
    final days = Map<int, DayHours>.of(value.days);
    if (hours == null) {
      days.remove(weekday);
    } else {
      days[weekday] = hours;
    }
    onChanged(OpeningHours(days: days));
  }

  Future<void> _pick(
    BuildContext context,
    int weekday,
    DayHours current, {
    required bool isOpen,
  }) async {
    final minute = isOpen ? current.openMinute : current.closeMinute;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
    );
    if (picked == null) return;
    final pickedMinute = picked.hour * 60 + picked.minute;
    _setDay(
      weekday,
      DayHours(
        openMinute: isOpen ? pickedMinute : current.openMinute,
        closeMinute: isOpen ? current.closeMinute : pickedMinute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in _dayNames.entries)
          _row(context, entry.key, entry.value),
      ],
    );
  }

  Widget _row(BuildContext context, int weekday, String name) {
    final hours = value.days[weekday];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            key: ValueKey('hours-switch-$weekday'),
            value: hours != null,
            onChanged: (on) => _setDay(weekday, on ? _defaultHours : null),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: hours == null
                ? const Text(
                    'ปิด',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.graySecondary,
                    ),
                  )
                : Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      TextButton(
                        key: ValueKey('hours-open-$weekday'),
                        onPressed: () =>
                            _pick(context, weekday, hours, isOpen: true),
                        child: Text(formatMinute(hours.openMinute)),
                      ),
                      const Text('-'),
                      TextButton(
                        key: ValueKey('hours-close-$weekday'),
                        onPressed: () =>
                            _pick(context, weekday, hours, isOpen: false),
                        child: Text(formatMinute(hours.closeMinute)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

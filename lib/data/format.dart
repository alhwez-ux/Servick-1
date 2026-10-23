const riyadhOffset = Duration(hours: 3);

const arabicMonths = <String>[
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// Keeps digits in left-to-right order inside Arabic text.
String isolateLtr(String value) => '\u202A$value\u202C';

String formatRiyadh(DateTime dateTime) {
  final wall = dateTime.toUtc().add(riyadhOffset);
  final hour = wall.hour.toString().padLeft(2, '0');
  final minute = wall.minute.toString().padLeft(2, '0');
  return '${wall.day} ${arabicMonths[wall.month - 1]} · ${isolateLtr('$hour:$minute')}';
}

String formatSubscriptionDate(DateTime dateTime) {
  final wall = dateTime.toUtc().add(riyadhOffset);
  final year = wall.year.toString().padLeft(4, '0');
  final month = wall.month.toString().padLeft(2, '0');
  final day = wall.day.toString().padLeft(2, '0');
  return isolateLtr('$year/$month/$day');
}

String formatPhone(String digits) {
  final pretty = RegExp(r'^05\d{8}$').hasMatch(digits)
      ? '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}'
      : digits;
  return isolateLtr(pretty);
}

String initialOf(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '؟';
  return trimmed.substring(0, 1);
}

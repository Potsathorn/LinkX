import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter._();
  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _dayTime = DateFormat('d MMM, HH:mm');
  static final DateFormat _full = DateFormat('d MMM yyyy, HH:mm');

  static String relative(DateTime value, {DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    final Duration diff = reference.difference(value);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (_isSameDay(value, reference)) return 'Today ${_time.format(value)}';
    if (_isSameDay(value, reference.subtract(const Duration(days: 1)))) {
      return 'Yesterday ${_time.format(value)}';
    }
    if (value.year == reference.year) return _dayTime.format(value);
    return _full.format(value);
  }

  static String full(DateTime value) => _full.format(value);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

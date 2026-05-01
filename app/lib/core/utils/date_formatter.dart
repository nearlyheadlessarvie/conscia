import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 14) return '1 week ago';
    return DateFormat.yMMMd().format(date);
  }

  static String monthYear(DateTime date) {
    return DateFormat.yMMMM().format(date);
  }

  static String dayMonth(DateTime date) {
    return DateFormat.MMMd().format(date);
  }

  static String full(DateTime date) {
    return DateFormat.yMMMMd().format(date);
  }

  static String time(DateTime date) {
    return DateFormat.jm().format(date);
  }

  static String dateTime(DateTime date) {
    return '${DateFormat.yMMMd().format(date)} ${DateFormat.jm().format(date)}';
  }
}

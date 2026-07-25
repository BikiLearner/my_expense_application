import 'package:intl/intl.dart';

class DateConstants {
  DateConstants._();

  static const List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String monthName(int month) => months[month - 1];

  // 25/07/2026
  static String ddMMyyyy(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // 25 Jul 2026
  static String ddMMMyyyy(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // 25 July 2026
  static String fullDate(DateTime date) {
    return DateFormat('dd MMMM yyyy').format(date);
  }

  // July 2026
  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  // Jul 2026
  static String shortMonthYear(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }
}
class CompactNumberFormatter {
  static String format(num number) {
    if (number >= 10000000) {
      return "${_format(number / 10000000)}Cr";
    }

    if (number >= 100000) {
      return "${_format(number / 100000)}L";
    }

    if (number >= 1000) {
      return "${_format(number / 1000)}K";
    }

    return number.toString();
  }

  static String _format(num number) {
    return number.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }
}
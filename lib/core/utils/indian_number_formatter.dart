import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class IndianNumberFormatter extends TextInputFormatter {

  static final NumberFormat _formatter = NumberFormat.decimalPattern('en_IN');
  /// For display: 150000 -> "1,50,000"
  static String format(num value) => _formatter.format(value);
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove commas
    final numericString = newValue.text.replaceAll(',', '');

    // Prevent invalid input
    final number = int.tryParse(numericString);
    if (number == null) {
      return oldValue;
    }

    final newText = _formatter.format(number);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

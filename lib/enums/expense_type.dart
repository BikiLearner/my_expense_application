import 'package:flutter/material.dart';

enum ExpenseType { saving, needed, luxury }

ExpenseType parseExpenseType(dynamic value) {
  if (value is String) {
    return ExpenseType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseType.luxury, // 🔴 default
    );
  }
  return ExpenseType.luxury;
}

extension ExpenseTypeUI on ExpenseType {
  String get label {
    switch (this) {
      case ExpenseType.saving:
        return 'Saving';
      case ExpenseType.needed:
        return 'Needed';
      case ExpenseType.luxury:
        return 'Luxury';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseType.saving:
        return Icons.savings_outlined;
      case ExpenseType.needed:
        return Icons.shopping_cart_outlined;
      case ExpenseType.luxury:
        return Icons.auto_awesome_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseType.saving:
        return Colors.greenAccent;
      case ExpenseType.needed:
        return Colors.blueAccent;
      case ExpenseType.luxury:
        return Colors.purpleAccent;
    }
  }
}

import 'package:flutter/material.dart';

import '../enums/expense_type.dart';
import 'type_button.dart';

class ExpenseTypeSelector extends StatelessWidget {
  final ExpenseType selectedType;
  final ValueChanged<ExpenseType> onChanged;

  const ExpenseTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TypeButton(
          type: ExpenseType.saving,
          selected: selectedType == ExpenseType.saving,
          onTap: () => onChanged(ExpenseType.saving),
        ),
        TypeButton(
          type: ExpenseType.needed,
          selected: selectedType == ExpenseType.needed,
          onTap: () => onChanged(ExpenseType.needed),
        ),
        TypeButton(
          type: ExpenseType.luxury,
          selected: selectedType == ExpenseType.luxury,
          onTap: () => onChanged(ExpenseType.luxury),
        ),
      ],
    );
  }
}
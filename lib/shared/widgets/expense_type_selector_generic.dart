import 'package:flutter/material.dart';

import '../enums/expense_type.dart';
import 'type_button.dart';
import '../providers/expense_type_selector_provider.dart';

class ExpenseTypeSelector extends StatelessWidget {
  final ExpenseTypeProvider provider;

  const ExpenseTypeSelector({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final selectedType = provider.selectedType;

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TypeButton(
              provider: provider,
              type: ExpenseType.saving,
              selected: selectedType == ExpenseType.saving,
            ),
            TypeButton(
              provider: provider,
              type: ExpenseType.needed,
              selected: selectedType == ExpenseType.needed,
            ),
            TypeButton(
              provider: provider,
              type: ExpenseType.luxury,
              selected: selectedType == ExpenseType.luxury,
            ),
          ],
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../enums/expense_type.dart';
import '../provider/expence_provider.dart';
import 'type_button.dart';

class ExpenseTypeSelector extends StatelessWidget {
  const ExpenseTypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ExpenseProvider, ExpenseType>(
      selector: (_, provider) => provider.selectedType,
      builder: (context, selectedType, _) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TypeButton(
              type: ExpenseType.saving,
              selected: selectedType == ExpenseType.saving,
            ),
            TypeButton(
              type: ExpenseType.needed,
              selected: selectedType == ExpenseType.needed,
            ),
            TypeButton(
              type: ExpenseType.luxury,
              selected: selectedType == ExpenseType.luxury,
            ),
          ],
        );
      },
    );
  }
}

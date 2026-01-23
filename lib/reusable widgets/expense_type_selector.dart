import 'package:expence_app/reusable%20widgets/type_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../enums/expense_type.dart';
import '../providers/expence_provider.dart';

class ExpenseTypeSelector extends StatelessWidget {
  const ExpenseTypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ExpenseProvider, ExpenseType>(
        selector: (_, provider) => provider.selectedType,
        builder: (context, selectedType, _) {
          return Column(
              children: [
                TypeButton(
                    type: ExpenseType.saving,
                    selected: selectedType == ExpenseType.saving
                ),
                const SizedBox(height: 12),
                TypeButton(
                    type: ExpenseType.needed,
                    selected: selectedType == ExpenseType.needed
                ),
                const SizedBox(height: 12),
                TypeButton(
                    type: ExpenseType.luxury,
                    selected: selectedType == ExpenseType.luxury
                )
              ]
          );
        }
    );
  }
}
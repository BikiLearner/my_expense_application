
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../enums/transaction_type_enum.dart';
import '../providers/expence_provider.dart';

class TransactionTypeChips extends StatelessWidget {
  const TransactionTypeChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ExpenseProvider, TransactionTypeEnum>(
      selector: (_, p) => p.selectedTransaction,
      builder: (_, selected, __) {
        return Wrap(
          spacing: 8,
          children: TransactionTypeEnum.values.map((type) {
            final isSelected = selected == type;

            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: 18,
                    color: isSelected ? Colors.black : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(type.label),
                ],
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF64FFDA),
              backgroundColor: const Color(0xFF2C2C2C),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) {
                context.read<ExpenseProvider>().setTransactionType(type);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
import 'package:expence_app/reusable%20widgets/transaction_type_chips.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expence_provider.dart';
import 'app_text_fields.dart';
import 'auto_complete_text_fields.dart';
import 'expense_type_selector.dart';

class EditExpenseForm extends StatelessWidget {
  const EditExpenseForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TransactionTypeChips(),
              const SizedBox(height: 16),
              TitleAutoCompleteField(controller: provider.titleController),
              const SizedBox(height: 16),
              AppTextField(
                controller: provider.amountController,
                label: 'Amount',
                hint: 'Enter amount',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: provider.descriptionController,
                label: 'Description (Optional)',
                hint: 'Add details...',
                icon: Icons.notes,
                maxLines: 3,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ExpenseTypeSelector(),
      ],
    );
  }
}

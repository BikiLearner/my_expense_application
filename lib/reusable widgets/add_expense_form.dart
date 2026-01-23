import 'package:expence_app/reusable%20widgets/transaction_type_chips.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expence_provider.dart';
import 'app_text_fields.dart';
import 'auto_complete_text_fields.dart';
import 'expense_type_selector.dart';

class AddExpenseForm extends StatelessWidget {
  final bool isDesktop;

  const AddExpenseForm({
    super.key,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();

    return Container(
      color: isDesktop ? const Color(0xFF1E1E1E) : const Color(0xFF1A1A1A),
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            const Text(
              'Add New Expense',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the details below',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    TitleAutoCompleteField(
                      controller: provider.titleController,
                    ),
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
                    const SizedBox(height: 16),
                    TransactionTypeChips(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ExpenseTypeSelector(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: provider.addExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64FFDA),
                foregroundColor: const Color(0xFF121212),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline),
                  SizedBox(width: 8),
                  Text(
                    'Add Expense',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:expence_app/enums/indian_number_formatter.dart';
import 'package:expence_app/reusable%20widgets/transaction_type_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

          /// 🔥 HEIGHT-SYNCED ROW
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// LEFT SIDE
                Expanded(
                  child: Column(
                    children: [
                      TitleAutoCompleteField(
                        controller: provider.titleController,
                      ),
                      const SizedBox(height: 16),

                      /// 💰 AMOUNT FIELD (INDIAN FORMAT – VISUAL ONLY)
                      AppTextField(
                        controller: provider.amountController,
                        label: 'Amount',
                        hint: 'Enter amount',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          IndianNumberFormatter(),
                        ],
                      ),

                      const SizedBox(height: 16),
                      AppTextField(
                        controller: provider.descriptionController,
                        label: 'Description (Optional)',
                        hint: 'Add details...',
                        icon: Icons.notes,
                      ),
                      const SizedBox(height: 16),
                      const TransactionTypeChips(),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                /// RIGHT SIDE
                const ExpenseTypeSelector(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          /// 🔹 ADD BUTTON
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

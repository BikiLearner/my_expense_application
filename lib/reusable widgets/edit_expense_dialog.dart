import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense_items.dart';
import '../providers/expence_provider.dart';
import 'edit_expense_form.dart';

class EditExpenseDialog extends StatelessWidget {
  final ExpenseItem expense;

  const EditExpenseDialog({
    super.key,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();

    // Pre-fill
    provider.titleController.text = expense.title;
    provider.amountController.text = expense.amount.toString();
    provider.descriptionController.text = expense.description;
    provider.setExpenseType(expense.type);

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Edit Expense',
        style: TextStyle(color: Colors.white),
      ),
      content: const SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: EditExpenseForm(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            provider.clearForm();
            Navigator.pop(context);
          },
          child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
        ),
        ElevatedButton(
          onPressed: () async {
            await provider.editExpense(
              docId: expense.id,
              oldAmount: expense.amount,
              oldType: expense.type,
              oldDate: expense.createdAt,
            );

            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF64FFDA),
            foregroundColor: const Color(0xFF121212),
          ),
          child: const Text(
            'Update Expense',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

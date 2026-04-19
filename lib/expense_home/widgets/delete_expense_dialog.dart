import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense_items.dart';
import '../provider/expence_provider.dart';

class DeleteExpenseDialog extends StatelessWidget {
  final ExpenseItem expense;

  const DeleteExpenseDialog({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
          SizedBox(width: 12),
          Text('Delete Expense?', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Text(
        'Are you sure you want to delete "${expense.title}"?',
        style: TextStyle(color: Colors.grey[400]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
        ),
        ElevatedButton(
          onPressed: () {
            provider.deleteExpense(
              docId: expense.id,
              amount: expense.amount,
              type: expense.type,
              dateId: expense.dateId,
              bankId: expense.transactionType
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

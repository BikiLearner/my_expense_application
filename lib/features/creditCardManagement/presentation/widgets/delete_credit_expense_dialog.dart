import 'package:expence_app/features/creditCardManagement/data/model/credit_card_expense_item_model.dart';
import 'package:expence_app/features/creditCardManagement/presentation/provider/credit_expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color.dart';

class DeleteCreditExpenseDialog extends StatelessWidget {
  final CreditExpenseItem expense;

  const DeleteCreditExpenseDialog({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CreditExpenseProvider>();

    return AlertDialog(
      backgroundColor: AppColor.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColor.paletteOrange),
          SizedBox(width: 12),
          Text(
            'Delete Expense?',
            style: TextStyle(color: AppColor.textPrimary),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to delete "${expense.title}"?',
        style: const TextStyle(color: AppColor.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColor.textGrey),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            provider.deleteExpense(context: context, expenseId: expense.id);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColor.twRed),
          child: const Text(
            'Delete',
            style: TextStyle(color: AppColor.textPrimary),
          ),
        ),
      ],
    );
  }
}

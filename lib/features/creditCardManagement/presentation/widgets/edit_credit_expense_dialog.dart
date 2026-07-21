import 'package:expence_app/features/creditCardManagement/data/model/credit_card_expense_item_model.dart';
import 'package:expence_app/features/creditCardManagement/presentation/provider/credit_expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'edit_credit_expense_form.dart';

class EditCreditExpenseDialog extends StatefulWidget {
  final CreditExpenseItem expense;

  const EditCreditExpenseDialog({super.key, required this.expense});

  @override
  State<EditCreditExpenseDialog> createState() =>
      _EditCreditExpenseDialogState();
}

class _EditCreditExpenseDialogState extends State<EditCreditExpenseDialog> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Initialize immediately in initState (before build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CreditExpenseProvider>();

      // Set all values
      provider.setTitle(widget.expense.title);
      provider.amountController.text = widget.expense.amount.toString();
      provider.descriptionController.text = widget.expense.description;
      provider.setExpenseType(widget.expense.type);

      setState(() {
        _isInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    // Don't clear form on dispose - let the buttons handle it
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading until initialized
    if (!_isInitialized) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const SizedBox(
          width: 100,
          height: 100,
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
          ),
        ),
      );
    }

    return Consumer<CreditExpenseProvider>(
      builder: (context, provider, _) {
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
            child: SingleChildScrollView(child: EditCreditExpenseForm()),
          ),
          actions: [
            TextButton(
              onPressed: () {
                provider.clearForm();
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                await provider.editExpense(
                  context: context,
                  docId: widget.expense.id,
                );

                if (context.mounted) {
                  provider.clearForm();
                  Navigator.pop(context);
                }
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
      },
    );
  }
}

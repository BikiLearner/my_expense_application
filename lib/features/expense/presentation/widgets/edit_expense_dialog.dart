import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../bank/data/model/bank_model.dart';
import '../../../bank/presentation/provider/bank_provider.dart';
import '../../data/model/expense_items.dart';
import '../provider/expence_provider.dart';
import 'edit_expense_form.dart';

class EditExpenseDialog extends StatefulWidget {
  final ExpenseItem expense;

  const EditExpenseDialog({super.key, required this.expense});

  @override
  State<EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends State<EditExpenseDialog> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Initialize immediately in initState (before build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ExpenseProvider>();

      // Set all values
      provider.setTitle(widget.expense.title);
      provider.amountController.text = widget.expense.amount.toString();
      provider.descriptionController.text = widget.expense.description;
      provider.setExpenseType(widget.expense.type);

      // Set transaction type/bank
      if (widget.expense.transactionType != null &&
          widget.expense.transactionType != 'cash') {
        // Find the bank from BankProvider
        final banks = context.read<BankProvider>().banks;
        final bank = banks.firstWhere(
              (b) => b.id == widget.expense.transactionType,
        );
        provider.setTransactionType(bank);
      }

      // Mark as initialized and rebuild
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
            child: CircularProgressIndicator(
              color: Color(0xFF64FFDA),
            ),
          ),
        ),
      );
    }

    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Edit Expense',
            style: TextStyle(color: Colors.white),
          ),
          content: const SizedBox(
            width: 400,
            child: SingleChildScrollView(child: EditExpenseForm()),
          ),
          actions: [
            TextButton(
              onPressed: () {
                provider.clearForm();
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await provider.editExpense(
                  context: context,
                  docId: widget.expense.id,
                  oldAmount: widget.expense.amount,
                  oldType: widget.expense.type,
                  oldDate: widget.expense.createdAt,
                  oldTransactionTypeId: widget.expense.transactionType,
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
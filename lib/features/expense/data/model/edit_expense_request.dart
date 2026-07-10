import 'expense_items.dart';

class EditExpenseRequest {
  final ExpenseItem oldExpense;
  final ExpenseItem updatedExpense;

  const EditExpenseRequest({
    required this.oldExpense,
    required this.updatedExpense,
  });
}
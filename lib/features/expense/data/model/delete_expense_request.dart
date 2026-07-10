import 'expense_items.dart';

class DeleteExpenseRequest {
  final ExpenseItem expense;

  const DeleteExpenseRequest({
    required this.expense,
  });
}
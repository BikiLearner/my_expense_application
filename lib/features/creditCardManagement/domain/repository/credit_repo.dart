import '../../data/model/credit_card_expense_item_model.dart';

abstract class CreditRepository {
  Future<void> addCreditExpense({
    required String title,
    required double amount,
    required String description,
    required String expenseTypeName,
    required String creditCardId,
    required DateTime purchaseDate,
    required String billingCycleId,
  });

  Stream<List<CreditExpenseItem>> watchCreditExpenses({
    required String creditCardId,
    required String billingCycleId,
    required DateTime selectedDate,
  });
}
import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';

import '../../data/model/billing_cycle_model.dart';
import '../../data/model/credit_card_expense_item_model.dart';
import '../../data/model/credit_payment.dart';

abstract class CreditRepository {
  Future<void> createCreditCard({
    required String cardName,
    required String bankName,
    required double creditLimit,
    required int statementDay,
    required int dueDay,
  });

  Future<void> updateCreditCard();

  Future<List<CreditCardModel>> fetchCreditCards();

  Future<BillingCycleModel> createBillingCycleIfNeeded(
    CreditCardModel card,
    DateTime expenseDate,
  );

  Stream<BillingCycleModel?> watchBillingCycle({
    required String creditCardId,
    required String billingCycleId,
  });

  Future<void> addCreditExpense({
    required CreditCardModel card,
    required String title,
    required double amount,
    required String description,
    required String expenseTypeName,
    int split=0,
    required DateTime purchaseDate,
  });

  Stream<List<CreditExpenseItem>> watchCreditExpenses({
    required String creditCardId,
    required String billingCycleId,
  });

  Stream<List<CreditExpenseItem>> watchCreditExpensesByDate({
    required String creditCardId,
    required String billingCycleId,
    required DateTime selectedDate,
  });

  Future<void> editCreditExpense({
    required String creditCardId,
    required String billingCycleId,
    required String expenseId,
    required String title,
    required double amount,
    required String description,
    int split=0,
    required String expenseTypeName,
    required DateTime purchaseDate,
  });

  Future<void> deleteCreditExpense({
    required String creditCardId,
    required String billingCycleId,
    required String expenseId,
  });

  Future<bool> payCreditCard({
    required CreditPaymentModel payment,
    required String creditCardId,
    required String billingCycleId,
  });

  Future<List<CreditExpenseItem>> fetchCreditExpensesByBillingCycleId({
    required String creditCardId,
    required String billingCycleId,
  });

  Future<List<BillingCycleModel>> fetchBillingCycles({
    required String creditCardId,
  });
}

import 'package:expence_app/features/creditCardManagement/data/model/billing_cycle_model.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';

import '../../domain/repository/credit_repo.dart';
import '../datasource/credit_firestore_datasource.dart';
import '../model/credit_card_expense_item_model.dart';

class CreditRepositoryImpl implements CreditRepository {
  CreditRepositoryImpl({CreditFirestoreDatasource? datasource})
    : _datasource = datasource ?? CreditFirestoreDatasource();

  final CreditFirestoreDatasource _datasource;

  @override
  Future<void> addCreditExpense({
    required CreditCardModel card,
    required String title,
    required double amount,
    required String description,
    required String expenseTypeName,
    int split=0,
    required DateTime purchaseDate,
  }) {
    return _datasource.addCreditExpense(
      card: card,
      title: title,
      amount: amount,
      description: description,
      split: split,
      expenseTypeName: expenseTypeName,
      purchaseDate: purchaseDate,
    );
  }

  @override
  Stream<List<CreditExpenseItem>> watchCreditExpenses({
    required String creditCardId,
    required String billingCycleId,
  }) {
    return _datasource.watchCreditExpenses(
      creditCardId: creditCardId,
      billingCycleId: billingCycleId,
    );
  }

  @override
  Future<List<CreditCardModel>> fetchCreditCards() {
    return _datasource.fetchCreditCards();
  }

  @override
  Future<void> updateCreditCard() {
    // TODO: implement updateCreditCard
    throw UnimplementedError();
  }

  @override
  Future<void> createCreditCard({
    required String cardName,
    required String bankName,
    required double creditLimit,
    required int statementDay,
    required int dueDay,
  }) {
    return _datasource.createCreditCard(
      cardName: cardName,
      bankName: bankName,
      creditLimit: creditLimit,
      statementDay: statementDay,
      dueDay: dueDay,
    );
  }

  @override
  Future<BillingCycleModel> createBillingCycleIfNeeded(
    CreditCardModel card,
    DateTime expenseDate,
  ) {
    return _datasource.createBillingCycleIfNeeded(card, expenseDate);
  }

  @override
  Stream<BillingCycleModel?> watchBillingCycle({
    required String creditCardId,
    required String billingCycleId,
  }) {
    return _datasource.watchBillingCycle(
      creditCardId: creditCardId,
      billingCycleId: billingCycleId,
    );
  }

  @override
  Stream<List<CreditExpenseItem>> watchCreditExpensesByDate({
    required String creditCardId,
    required String billingCycleId,
    required DateTime selectedDate,
  }) {
    return _datasource.watchCreditExpensesByDate(
      creditCardId: creditCardId,
      billingCycleId: billingCycleId,
      selectedDate: selectedDate,
    );
  }

  @override
  Future<void> editCreditExpense({
    required String creditCardId,
    required String billingCycleId,
    required String expenseId,
    required String title,
    required double amount,
    required String description,
    required String expenseTypeName,
    int split=0,
    required DateTime purchaseDate,
  }) {
    return _datasource.editCreditExpense(
      creditCardId: creditCardId,
      billingCycleId: billingCycleId,
      expenseId: expenseId,
      title: title,
      amount: amount,
      description: description,
      split: split,
      expenseTypeName: expenseTypeName,
      purchaseDate: purchaseDate,
    );
  }

  @override
  Future<void> deleteCreditExpense({
    required String creditCardId,
    required String billingCycleId,
    required String expenseId,
  }) {
    return _datasource.deleteCreditExpense(
      creditCardId: creditCardId,
      billingCycleId: billingCycleId,
      expenseId: expenseId,
    );
  }
}

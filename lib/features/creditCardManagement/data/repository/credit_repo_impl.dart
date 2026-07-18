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
    required String title,
    required double amount,
    required String description,
    required String expenseTypeName,
    required String creditCardId,
    required DateTime purchaseDate,
    required String billingCycleId,
  }) {
    return _datasource.addCreditExpense(
      title: title,
      amount: amount,
      description: description,
      expenseTypeName: expenseTypeName,
      creditCardId: creditCardId,
      purchaseDate: purchaseDate,
      billingCycleId: billingCycleId,
    );
  }

  @override
  Stream<List<CreditExpenseItem>> watchCreditExpenses({
    required String creditCardId,
    required String billingCycleId,
    required DateTime selectedDate,
  }) {
    return _datasource.watchCreditExpenses(
      creditCardId: creditCardId,
      billingCycleId: billingCycleId,
      selectedDate: selectedDate,
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
}

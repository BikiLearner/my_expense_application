// expense_repository_impl.dart
//
// Thin pass-through implementation of ExpenseRepository. All Firestore work
// happens in ExpenseFirestoreDatasource; this class only wires the domain
// contract to that datasource.

import '../../domain/repository/expense_repository.dart';
import '../../../../shared/models/month_stats.dart';
import '../../../../shared/models/year_stats.dart';
import '../datasource/expense_firestore_datasource.dart';
import '../model/expense_items.dart';
import '../model/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl({ExpenseFirestoreDatasource? datasource})
      : _datasource = datasource ?? ExpenseFirestoreDatasource();

  final ExpenseFirestoreDatasource _datasource;

  @override
  Future<void> addExpense({
    required String uid,
    required String dateId,
    required String title,
    required double amount,
    required String description,
    required String expenseTypeName,
    required String? transactionTypeId,
    required DateTime itemCreatedAt,
  }) {
    return _datasource.addExpense(
      uid: uid,
      dateId: dateId,
      title: title,
      amount: amount,
      description: description,
      expenseTypeName: expenseTypeName,
      transactionTypeId: transactionTypeId,
      itemCreatedAt: itemCreatedAt,
    );
  }

  @override
  Future<void> editExpense({
    required String uid,
    required String docId,
    required double oldAmount,
    required String oldTypeName,
    required DateTime oldDate,
    required String? oldTransactionTypeId,
    required String title,
    required double newAmount,
    required String description,
    required String newTypeName,
    required String? newTransactionTypeId,
  }) {
    return _datasource.editExpense(
      uid: uid,
      docId: docId,
      oldAmount: oldAmount,
      oldTypeName: oldTypeName,
      oldDate: oldDate,
      oldTransactionTypeId: oldTransactionTypeId,
      title: title,
      newAmount: newAmount,
      description: description,
      newTypeName: newTypeName,
      newTransactionTypeId: newTransactionTypeId,
    );
  }

  @override
  Future<void> deleteExpense({
    required String uid,
    required String docId,
    required double amount,
    required String typeName,
    required String dateId,
    required String? bankId,
  }) {
    return _datasource.deleteExpense(
      uid: uid,
      docId: docId,
      amount: amount,
      typeName: typeName,
      dateId: dateId,
      bankId: bankId,
    );
  }

  @override
  Stream<List<ExpenseItem>> watchExpenses({
    required String uid,
    required String dateId,
  }) {
    return _datasource.watchExpenses(uid: uid, dateId: dateId);
  }

  @override
  Future<List<ExpenseDay>> getAllExpenseForEveryMonth({required String uid}) {
    return _datasource.getAllExpenseForEveryMonth(uid: uid);
  }

  @override
  Future<Map<String, List<ExpenseItem>>> getMonthExpenses({
    required String uid,
    required String monthKey,
  }) {
    return _datasource.getMonthExpenses(uid: uid, monthKey: monthKey);
  }

  @override
  Future<double> getTotalForDate({
    required String uid,
    required String dateId,
  }) {
    return _datasource.getTotalForDate(uid: uid, dateId: dateId);
  }





  @override
  Future<YearStats?> getYearStats({
    required String uid,
    required String year,
  }) {
    return _datasource.getYearStats(uid: uid, year: year);
  }

  @override
  Future<List<MonthStats>> getMonthStatsForYear({
    required String uid,
    required String year,
  }) {
    return _datasource.getMonthStatsForYear(uid: uid, year: year);
  }

  @override
  Future<MonthStats?> getMonthStatsByMonth({
    required String uid,
    required String year,
    required String month,
  }) {
    return _datasource.getMonthStatsByMonth(uid: uid, year: year, month: month);
  }

  @override
  Future<Map<String, List<ExpenseDay>>> getExpensesGroupedByMonthForType({
    required String uid,
    required String expenseTypeName,
  }) {
    return _datasource.getExpensesGroupedByMonthForType(
      uid: uid,
      expenseTypeName: expenseTypeName,
    );
  }
}
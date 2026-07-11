// expense_repository.dart
//
// Domain-layer contract. The Provider (presentation layer) depends on this
// abstraction, not on ExpenseFirestoreDatasource directly, so the data
// source could be swapped later without touching the Provider.
//
// Method signatures mirror ExpenseFirestoreDatasource exactly — this
// repository is a thin pass-through, it adds no business logic of its own
// (per the refactor spec: "do not redesign, do not optimize").

import '../../data/model/expense_items.dart';
import '../../../../shared/models/month_stats.dart';
import '../../../../shared/models/year_stats.dart';
import '../../data/model/expense_model.dart';

abstract class ExpenseRepository {
  Future<void> addExpense({
    required String uid,
    required String dateId,
    required String title,
    required double amount,
    required String description,
    required String expenseTypeName,
    required String? transactionTypeId,
    required DateTime itemCreatedAt,
  });

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
  });

  Future<void> deleteExpense({
    required String uid,
    required String docId,
    required double amount,
    required String typeName,
    required String dateId,
    required String? bankId,
  });

  Stream<List<ExpenseItem>> watchExpenses({
    required String uid,
    required String dateId,
  });

  Future<List<ExpenseDay>> getAllExpenseDays({required String uid});

  Future<Map<String, List<ExpenseItem>>> getMonthExpenses({
    required String uid,
    required String monthKey,
  });

  Future<double> getTotalForDate({required String uid, required String dateId});

  Future<void> addCategory({required String uid, required String title});

  Future<void> deleteCategory({
    required String uid,
    required String categoryTitle,
  });

  Future<List<String>> getCategories({required String uid});

  /// Balance of a bank's month document, or `null` if it doesn't exist.
  /// Used for the Provider's pre-flight balance check.
  Future<double?> getBankMonthBalance({
    required String uid,
    required String bankId,
    required String monthId,
  });

  // Extended (see note in ExpenseFirestoreDatasource):
  Future<YearStats?> getYearStats({required String uid, required String year});

  Future<List<MonthStats>> getMonthStatsForYear({
    required String uid,
    required String year,
  });

  Future<MonthStats?> getMonthStatsByMonth({
    required String uid,
    required String year,
    required String month,
  });

  Future<Map<String, List<ExpenseDay>>> getExpensesGroupedByMonthForType({
    required String uid,
    required String expenseTypeName,
  });
}
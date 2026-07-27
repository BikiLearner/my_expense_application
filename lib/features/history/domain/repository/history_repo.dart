import '../../../../shared/models/month_stats.dart';
import '../../../../shared/models/year_stats.dart';
import '../../../expense/data/model/expense_model.dart';

abstract class HistoryRepository {
  // ================= NORMAL EXPENSE =================

  Future<YearStats?> fetchYearStats({
    required String uid,
    required String selectedYear,
  });

  Future<MonthStats?> fetchMonthStats({
    required String uid,
    required String selectedYear,
    required int selectedMonth,
  });

  // ================= CREDIT EXPENSE =================

  Future<YearStats?> fetchCreditYearStats({
    required String uid,
    required String selectedYear,
  });
  Future<int> fetchYearExpenseDaysCount({
    required String uid,
    required String selectedYear,
    required int selectedMonth,
  });

  Future<List<ExpenseDay>> fetchYearExpenseDays({
    required String uid,
    required String selectedYear,
  });

  Future<MonthStats?> fetchCreditMonthStats({
    required String uid,
    required String selectedYear,
    required int selectedMonth,
  });
}
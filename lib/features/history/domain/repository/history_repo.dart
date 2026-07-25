import '../../../../shared/models/month_stats.dart';
import '../../../../shared/models/year_stats.dart';

abstract class HistoryRepository {
  Future<YearStats?> fetchYearStats({
    required String uid,
    required String selectedYear,
  });

  Future<MonthStats?> fetchMonthStats({
    required String uid,
    required String selectedYear,
    required int selectedMonth,
  });
}

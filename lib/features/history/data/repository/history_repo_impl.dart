import 'package:expence_app/features/history/data/datesource/history_date_source.dart';
import 'package:expence_app/features/history/domain/repository/history_repo.dart';
import 'package:expence_app/shared/models/month_stats.dart';
import 'package:expence_app/shared/models/year_stats.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({HistoryDataSource? datasource})
    : _datasource = datasource ?? HistoryDataSource();

  final HistoryDataSource _datasource;

  @override
  Future<MonthStats?> fetchMonthStats({
    required String uid,
    required String selectedYear,
    required int selectedMonth,
  }) {
    return _datasource.fetchMonthStats(
      uid: uid,
      selectedYear: selectedYear,
      selectedMonth: selectedMonth,
    );
  }

  @override
  Future<YearStats?> fetchYearStats({
    required String uid,
    required String selectedYear,
  }) {
    return _datasource.fetchYearStats(uid: uid, selectedYear: selectedYear);
  }
}

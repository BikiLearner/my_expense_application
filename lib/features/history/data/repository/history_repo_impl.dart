import 'package:expence_app/features/expense/data/model/expense_model.dart';
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

  @override
  Future<MonthStats?> fetchCreditMonthStats({
    required String uid,
    required String selectedYear,
    required int selectedMonth,
  }) {
    return _datasource.fetchCreditMonthStats(
      uid: uid,
      selectedYear: selectedYear,
      selectedMonth: selectedMonth,
    );
  }

  @override
  Future<YearStats?> fetchCreditYearStats({
    required String uid,
    required String selectedYear,
  }) {
    return _datasource.fetchCreditYearStats(
      uid: uid,
      selectedYear: selectedYear,
    );
  }

  @override
  Future<int> fetchYearExpenseDaysCount({
    required String uid,
    required String selectedYear,
    required int selectedMonth,
  }) {
    return _datasource.fetchYearExpenseDaysCount(
      uid: uid,
      selectedYear: selectedYear,
      selectedMonth: selectedMonth,
    );
  }
}

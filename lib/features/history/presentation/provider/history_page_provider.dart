import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expence_app/core/services/session_maganger.dart';
import 'package:expence_app/features/history/domain/repository/history_repo.dart';
import 'package:flutter/foundation.dart';

import '../../../../shared/models/month_stats.dart';
import '../../../../shared/models/year_stats.dart';
import '../../../expense/data/model/expense_model.dart';

class HistoryPageProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid = SessionManager.instance.requireUid;
  late String _selectedYear;
  late int _selectedMonth;

  String get selectedYear => _selectedYear;

  int get selectedMonth => _selectedMonth;
  final HistoryRepository _historyRepository;

  // Cache data
  YearStats? _yearStats;
  MonthStats? _monthStats;

  // Credit stats
  YearStats? _creditYearStats;
  MonthStats? _creditMonthStats;

  List<ExpenseDay> _yearExpenseDays = [];

  bool _isLoading = false;
  String? _error;

  HistoryPageProvider({required HistoryRepository historyRepository})
    : _historyRepository = historyRepository {
    final now = DateTime.now();

    _selectedYear = now.year.toString();
    _selectedMonth = now.month;
    fetchHistoryData();
  }

  // Getters
  YearStats? get yearStats => _yearStats;

  MonthStats? get monthStats => _monthStats;

  YearStats? get creditYearStats => _creditYearStats;

  MonthStats? get creditMonthStats => _creditMonthStats;


  double get creditSavingPercent {
    final stats = _creditMonthStats;
    if (stats == null || stats.grandTotal <= 0) return 0;

    return (stats.saving / stats.grandTotal) * 100;
  }

  double get creditLuxuryPercent {
    final stats = _creditMonthStats;
    if (stats == null || stats.grandTotal <= 0) return 0;

    return (stats.luxury / stats.grandTotal) * 100;
  }

  double get creditNeededPercent {
    final stats = _creditMonthStats;
    if (stats == null || stats.grandTotal <= 0) return 0;

    return (stats.needed / stats.grandTotal) * 100;
  }

  bool get isLoading => _isLoading;

  String? get error => _error;

  double get monthTotal => _monthStats?.grandTotal ?? 0.0;

  String get _selectedMonthId =>
      '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}';

  int get totalDays {
    final year = int.parse(_selectedYear);

    final daysInMonth = DateTime(year, _selectedMonth + 1, 0).day;

    return daysInMonth - monthExpenseDays.length;
  }

  double get avgPerDay => totalDays > 0 ? monthTotal / totalDays : 0.0;

  double get highestDay {
    if (monthExpenseDays.isEmpty) return 0.0;
    return monthExpenseDays.map((d) => d.total).reduce((a, b) => a > b ? a : b);
  }

  List<ExpenseDay> get monthExpenseDays {
    return _yearExpenseDays
        .where((d) => d.dateId.startsWith(_selectedMonthId))
        .toList();
  }

  void setYear(String year) {
    if (_selectedYear == year) return;
    _selectedYear = year;
    fetchHistoryData(); // 🔥
  }

  void setMonth(int month) {
    if (_selectedMonth == month) return;
    _selectedMonth = month;
    fetchHistoryData(); // 🔥 THIS WAS MISSING
  }

  /// Fetch all required data for the history screen
  Future<void> fetchHistoryData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _historyRepository.fetchMonthStats(
          uid: uid,
          selectedYear: selectedYear,
          selectedMonth: selectedMonth,
        ),
        _historyRepository.fetchYearStats(uid: uid, selectedYear: selectedYear),
        _historyRepository.fetchCreditYearStats(
          uid: uid,
          selectedYear: selectedYear,
        ),
        _historyRepository.fetchCreditMonthStats(
          uid: uid,
          selectedYear: selectedYear,
          selectedMonth: selectedMonth,
        ),
        _historyRepository.fetchYearExpenseDays(
          uid: uid,
          selectedYear: selectedYear,
        ),
      ]);

      _monthStats = results[0] as MonthStats?;
      _yearStats = results[1] as YearStats?;
      _creditYearStats = results[2] as YearStats?;
      _creditMonthStats = results[3] as MonthStats?;
      _yearExpenseDays = (results[4] as List<ExpenseDay>?) ?? [];

      _error = null;

      if (kDebugMode) {
        print("✅ Month Stats: $_monthStats");
        print("✅ Year Stats: $_yearStats");
        print("✅ Expense Days: ${_yearExpenseDays.length}");
      }
    } catch (e) {
      _error = e.toString();

      if (kDebugMode) {
        print("❌ Error fetching history data: $e");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await fetchHistoryData();
  }

  /// Get grouped expenses by month
  Map<String, List<ExpenseDay>> getGroupedByMonth() {
    final Map<String, List<ExpenseDay>> map = {};
    for (final d in _yearExpenseDays) {
      final key = d.dateId.substring(0, 7); // yyyy-MM
      map.putIfAbsent(key, () => []).add(d);
    }
    return map;
  }
}

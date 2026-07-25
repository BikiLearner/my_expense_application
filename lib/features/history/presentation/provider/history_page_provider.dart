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

  bool get isLoading => _isLoading;

  String? get error => _error;

  double get monthTotal => _monthStats?.grandTotal ?? 0.0;

  String get _selectedMonthId =>
      '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}';

  int get totalDays {
    final year = int.parse(_selectedYear);

    return DateTime(year, _selectedMonth + 1, 0).day;
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
        _historyRepository.fetchYearStats(
          uid: uid,
          selectedYear: selectedYear,
        ),
        _fetchYearExpenseDays(),
      ]);

      _monthStats = results[0] as MonthStats?;
      _yearStats = results[1] as YearStats?;

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

  /// Fetch year statistics

  /// Fetch ONLY the expense days for the selected year (NOT all years)
  Future<void> _fetchYearExpenseDays() async {
    try {
      // Query only documents that start with the selected year
      // This uses Firestore's string comparison for document IDs
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .where(
            FieldPath.documentId,
            isGreaterThanOrEqualTo: '$selectedYear-01-01',
          )
          .where(
            FieldPath.documentId,
            isLessThanOrEqualTo: '$selectedYear-12-31',
          )
          .get();

      _yearExpenseDays = snapshot.docs.map((doc) {
        return ExpenseDay(
          dateId: doc.id,
          total: (doc.data()['total'] ?? 0).toDouble(),
        );
      }).toList();

      // Sort by date (descending)
      _yearExpenseDays.sort((a, b) => b.dateId.compareTo(a.dateId));

      if (kDebugMode) {
        print(
          "✅ Fetched ${_yearExpenseDays.length} expense days for $selectedYear",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Failed to fetch year expense days: $e");
      }
      _yearExpenseDays = [];
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

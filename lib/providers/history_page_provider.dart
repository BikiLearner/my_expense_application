import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/month_stats.dart';
import '../models/year_stats.dart';
import '../expense_model.dart';

class HistoryPageProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid;
  String _selectedYear;
  int _selectedMonth;

  String get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;


  // Cache data
  YearStats? _yearStats;
  MonthStats? _monthStats;
  List<ExpenseDay> _yearExpenseDays = [];

  bool _isLoading = false;
  String? _error;

  HistoryPageProvider({
    required this.uid,
    required String selectedYear,
    required int selectedMonth,
  })  : _selectedYear = selectedYear,
        _selectedMonth = selectedMonth;


  // Getters
  YearStats? get yearStats => _yearStats;
  MonthStats? get monthStats => _monthStats;
  List<ExpenseDay> get yearExpenseDays => _yearExpenseDays;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get yearExpense => _yearStats?.grandTotal ?? 0.0;
  double get monthTotal => _monthStats?.grandTotal ?? 0.0;
  double get saving => _monthStats?.saving ?? 0.0;
  double get luxury => _monthStats?.luxury ?? 0.0;
  double get needed => _monthStats?.needed ?? 0.0;
  String get _selectedMonthId =>
      '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}';


  int get totalDays => monthExpenseDays.length;

  double get avgPerDay =>
      totalDays > 0 ? monthTotal / totalDays : 0.0;


  double get highestDay {
    if (monthExpenseDays.isEmpty) return 0.0;
    return monthExpenseDays
        .map((d) => d.total)
        .reduce((a, b) => a > b ? a : b);
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
      await Future.wait([
        _fetchYearStats(),
        _fetchMonthStats(),
        _fetchYearExpenseDays(),
      ]);

      _isLoading = false;
      _error = null;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      if (kDebugMode) {
        print("❌ Error fetching history data: $e");
      }
    }

    notifyListeners();
  }

  /// Fetch year statistics
  Future<void> _fetchYearStats() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('year_stats')
          .doc(selectedYear)
          .get();

      if (doc.exists) {
        _yearStats = YearStats.fromFirestore(doc.id, doc.data()!);
      } else {
        _yearStats = null;
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Failed to fetch year stats: $e");
      }
      _yearStats = null;
    }
  }

  /// Fetch month statistics
  Future<void> _fetchMonthStats() async {
    try {
      final monthId = '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('year_stats')
          .doc(selectedYear)
          .collection('months')
          .doc(monthId)
          .get();

      if (doc.exists) {
        _monthStats = MonthStats.fromFirestore(doc.id, doc.data()!);
      } else {
        _monthStats = null;
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Failed to fetch month stats: $e");
      }
      _monthStats = null;
    }
  }

  /// Fetch ONLY the expense days for the selected year (NOT all years)
  Future<void> _fetchYearExpenseDays() async {
    try {
      // Query only documents that start with the selected year
      // This uses Firestore's string comparison for document IDs
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$selectedYear-01-01')
          .where(FieldPath.documentId, isLessThanOrEqualTo: '$selectedYear-12-31')
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
        print("✅ Fetched ${_yearExpenseDays.length} expense days for $selectedYear");
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
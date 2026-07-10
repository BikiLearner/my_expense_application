import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum AnalyticsState { loading, empty, loaded }

class AnalyticsProvider extends ChangeNotifier {
  final String year;
  AnalyticsProvider({required this.year});

  // ─── State ───────────────────────────────────────────────
  AnalyticsState _state = AnalyticsState.loading;
  AnalyticsState get state => _state;

  // ─── Computed Fields ─────────────────────────────────────
  double totalSpent = 0;
  double totalIncome = 0;
  double totalLuxury = 0;
  double totalNeeded = 0;
  double totalSaving = 0;
  double peakDayAmount = 0;
  String peakDate = '';
  double avgDailySpend = 0;
  double highestMonthTotal = 0;
  double lowestMonthTotal = double.infinity;
  String highestMonth = '';
  String lowestMonth = '';
  int activeDays = 0;
  int totalTransactions = 0;

  // Monthly totals: { 'yyyy-MM' -> double }
  Map<String, double> monthlyTotals = {};

  // Category totals: { 'category' -> double }
  Map<String, double> categoryTotals = {};

  // Bank usage: { 'bankId' -> double }
  Map<String, double> bankUsage = {};
  Map<String, String> bankNames = {}; // bankId -> bankName

  // Daily totals: { 'yyyy-MM-dd' -> double }
  Map<String, double> dailyTotals = {};

  // Top expenses list
  List<TopExpenseEntry> topExpenses = [];

  // Monthly savings rate: { 'yyyy-MM' -> rate }
  Map<String, double> monthlySavingsRate = {};

  // Week day distribution: { 'Mon' -> total }
  Map<String, double> weekdaySpend = {};

  // Hour distribution: { hour(int) -> total }
  Map<int, double> hourlySpend = {};

  // Streak data
  int currentStreak = 0;
  int longestStreak = 0;
  int zeroSpendDays = 0;

  // ─── Firestore ───────────────────────────────────────────
  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ─── Load All ────────────────────────────────────────────
  Future<void> loadAll() async {
    _state = AnalyticsState.loading;
    notifyListeners();

    try {
      await Future.wait([
        _loadDailyExpenses(),
        _loadMonthStats(),
        _loadBankData(),
        _loadIncomes(),
      ]);

      _computeDerived();

      _state = totalSpent == 0 ? AnalyticsState.empty : AnalyticsState.loaded;
    } catch (e) {
      debugPrint('❌ Analytics load failed: $e');
      _state = AnalyticsState.empty;
    }

    notifyListeners();
  }

  // ─── 1. Daily Expenses ───────────────────────────────────
  Future<void> _loadDailyExpenses() async {
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('expenses')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$year-01-01')
        .where(FieldPath.documentId, isLessThanOrEqualTo: '$year-12-31')
        .get();

    dailyTotals = {};
    monthlyTotals = {};
    categoryTotals = {};
    bankUsage = {};
    topExpenses = [];
    weekdaySpend = {'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0};

    // Fetch all items in parallel
    final itemFutures = snap.docs.map((dateDoc) async {
      final dateId = dateDoc.id;
      final dayTotal = (dateDoc.data()['total'] ?? 0).toDouble();
      dailyTotals[dateId] = dayTotal;

      final monthKey = dateId.substring(0, 7);
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + dayTotal;

      // Weekday distribution
      try {
        final dt = DateTime.parse(dateId);
        final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final wdKey = weekdayNames[dt.weekday - 1];
        weekdaySpend[wdKey] = (weekdaySpend[wdKey] ?? 0) + dayTotal;
      } catch (_) {}

      // Fetch items for category & bank breakdown
      final itemsSnap = await dateDoc.reference.collection('items').get();
      for (final itemDoc in itemsSnap.docs) {
        final data = itemDoc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        final title = (data['title'] ?? 'Unknown') as String;
        final txType = (data['transactionType'] ?? 'cash') as String;

        // Category
        categoryTotals[title] = (categoryTotals[title] ?? 0) + amount;

        // Bank usage
        bankUsage[txType] = (bankUsage[txType] ?? 0) + amount;

        // Top expenses
        topExpenses.add(TopExpenseEntry(
          title: title,
          amount: amount,
          dateId: dateId,
          type: (data['type'] ?? 'luxury') as String,
          bankId: txType,
        ));

        totalTransactions++;
      }
    });

    await Future.wait(itemFutures);

    // Sort top expenses
    topExpenses.sort((a, b) => b.amount.compareTo(a.amount));
    if (topExpenses.length > 20) topExpenses = topExpenses.sublist(0, 20);
  }

  // ─── 2. Month Stats ──────────────────────────────────────
  Future<void> _loadMonthStats() async {
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('year_stats')
        .doc(year)
        .collection('months')
        .get();

    totalLuxury = 0;
    totalNeeded = 0;
    totalSaving = 0;
    monthlySavingsRate = {};

    for (final doc in snap.docs) {
      final data = doc.data();
      final lux = (data['luxury'] ?? 0).toDouble();
      final need = (data['needed'] ?? 0).toDouble();
      final sav = (data['saving'] ?? 0).toDouble();
      totalLuxury += lux;
      totalNeeded += need;
      totalSaving += sav;

      final monthTotal = (data['grandTotal'] ?? 0).toDouble();
      if (monthTotal > 0) {
        monthlySavingsRate[doc.id] = sav / monthTotal;
      }
    }

    totalSpent = totalLuxury + totalNeeded + totalSaving;
  }

  // ─── 3. Bank Data ────────────────────────────────────────
  Future<void> _loadBankData() async {
    try {
      final snap = await _db
          .collection('users')
          .doc(_uid)
          .collection('bank')
          .get();

      for (final doc in snap.docs) {
        bankNames[doc.id] = (doc.data()['bankName'] ?? 'Unknown Bank') as String;
      }
      bankNames['cash'] = '💵 Cash';
    } catch (e) {
      debugPrint('Bank load error: $e');
    }
  }

  // ─── 4. Income ───────────────────────────────────────────
  Future<void> _loadIncomes() async {
    try {
      final snap = await _db
          .collection('users')
          .doc(_uid)
          .collection('incomes')
          .get();

      totalIncome = 0;
      for (final doc in snap.docs) {
        if (doc.id.startsWith(year)) {
          totalIncome += (doc.data()['total'] ?? 0).toDouble();
        }
      }
    } catch (e) {
      debugPrint('Income load error: $e');
    }
  }

  // ─── Compute Derived Metrics ─────────────────────────────
  void _computeDerived() {
    // Peak day
    peakDayAmount = 0;
    peakDate = '';
    for (final entry in dailyTotals.entries) {
      if (entry.value > peakDayAmount) {
        peakDayAmount = entry.value;
        peakDate = entry.key;
      }
    }

    // Active days & avg
    activeDays = dailyTotals.values.where((v) => v > 0).length;
    avgDailySpend = activeDays > 0 ? totalSpent / activeDays : 0;

    // Highest/lowest month
    highestMonthTotal = 0;
    lowestMonthTotal = double.infinity;
    for (final entry in monthlyTotals.entries) {
      if (entry.value > highestMonthTotal) {
        highestMonthTotal = entry.value;
        highestMonth = entry.key;
      }
      if (entry.value > 0 && entry.value < lowestMonthTotal) {
        lowestMonthTotal = entry.value;
        lowestMonth = entry.key;
      }
    }
    if (lowestMonthTotal == double.infinity) lowestMonthTotal = 0;

    // Streak computation
    _computeStreaks();

    // Zero spend days (within year up to today)
    final now = DateTime.now();
    final endDate = now.year.toString() == year ? now : DateTime(int.parse(year), 12, 31);
    final startDate = DateTime(int.parse(year), 1, 1);
    int totalDays = endDate.difference(startDate).inDays + 1;
    zeroSpendDays = totalDays - activeDays;
  }

  void _computeStreaks() {
    final now = DateTime.now();
    final sortedDates = dailyTotals.keys.where((d) {
      try {
        final dt = DateTime.parse(d);
        return dailyTotals[d]! > 0 && !dt.isAfter(now);
      } catch (_) {
        return false;
      }
    }).toList()
      ..sort();

    if (sortedDates.isEmpty) {
      currentStreak = 0;
      longestStreak = 0;
      return;
    }

    // Longest streak
    int maxStreak = 1;
    int streak = 1;
    for (int i = 1; i < sortedDates.length; i++) {
      final prev = DateTime.parse(sortedDates[i - 1]);
      final curr = DateTime.parse(sortedDates[i]);
      if (curr.difference(prev).inDays == 1) {
        streak++;
        if (streak > maxStreak) maxStreak = streak;
      } else {
        streak = 1;
      }
    }
    longestStreak = maxStreak;

    // Current streak (from today backwards)
    currentStreak = 0;
    DateTime check = DateTime(now.year, now.month, now.day);
    while (true) {
      final key = '${check.year}-${check.month.toString().padLeft(2, '0')}-${check.day.toString().padLeft(2, '0')}';
      if (dailyTotals.containsKey(key) && (dailyTotals[key] ?? 0) > 0) {
        currentStreak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
  }
}

// ─── Models ──────────────────────────────────────────────────
class TopExpenseEntry {
  final String title;
  final double amount;
  final String dateId;
  final String type;
  final String bankId;

  const TopExpenseEntry({
    required this.title,
    required this.amount,
    required this.dateId,
    required this.type,
    required this.bankId,
  });
}
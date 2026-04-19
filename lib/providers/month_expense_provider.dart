import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../enums/expense_type.dart';
import '../expense_home/models/expense_items.dart';


class MonthExpensesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // 🔹 Current month being watched
  String _currentMonth = ''; // yyyy-MM format
  String get currentMonth => _currentMonth;

  // 🔹 Cached expenses grouped by date
  Map<String, List<ExpenseItem>> _cachedExpenses = {};
  Map<String, List<ExpenseItem>> get groupedExpenses => _cachedExpenses;

  // 🔹 Stream subscriptions for each date in the month
  final Map<String, StreamSubscription<QuerySnapshot>> _dateSubscriptions = {};

  // 🔹 Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  /// 🔹 Total days with at least one expense
  int get totalDays => _cachedExpenses.length;
  /// 🔹 Average expense per day
  double get avgPerDay {
    if (totalDays == 0) return 0.0;
    return monthTotal / totalDays;
  }
  /// 🔹 Highest spending day amount
  double get highestDay {
    if (_cachedExpenses.isEmpty) return 0.0;

    double max = 0.0;
    for (final items in _cachedExpenses.values) {
      final dayTotal =
      items.fold(0.0, (sum, item) => sum + item.amount);
      if (dayTotal > max) {
        max = dayTotal;
      }
    }
    return max;
  }

  // 🔹 Total for the month (calculated from cache)
  double get monthTotal {
    double total = 0;
    for (final items in _cachedExpenses.values) {
      total += items.fold(0.0, (sum, item) => sum + item.amount);
    }
    return total;
  }

  // 🔹 Total number of items in the month
  int get totalItems {
    int count = 0;
    for (final items in _cachedExpenses.values) {
      count += items.length;
    }
    return count;
  }

  // 🔹 Get expenses for a specific date
  List<ExpenseItem> getExpensesForDate(String dateId) {
    return _cachedExpenses[dateId] ?? [];
  }

  // 🔹 Get total for a specific date
  double getTotalForDate(String dateId) {
    final items = _cachedExpenses[dateId] ?? [];
    return items.fold(0.0, (sum, item) => sum + item.amount);
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔄 STREAM MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// Set the month to watch and start streaming
  Future<void> setMonth(String monthKey) async {
    // yyyy-MM format (e.g., '2025-01')
    if (_currentMonth == monthKey) {
      return; // Already watching this month
    }

    if (kDebugMode) {
      print("📅 Switching to month: $monthKey");
    }

    // Cancel all previous subscriptions
    _cancelAllSubscriptions();

    // Clear cache
    _cachedExpenses.clear();
    _currentMonth = monthKey;
    _isLoading = true;
    notifyListeners();

    try {
      // Subscribe to all dates in this month
      await _subscribeToMonthDates(monthKey);
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error setting month: $e");
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Subscribe to all date documents for the current month
  Future<void> _subscribeToMonthDates(String monthKey) async {
    try {
      // Get all expense date documents for this month
      final expensesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$monthKey-01')
          .where(FieldPath.documentId, isLessThan: '$monthKey-32')
          .get();

      if (kDebugMode) {
        print("📊 Found ${expensesSnapshot.docs.length} dates in $monthKey");
      }

      // Subscribe to items for each date
      for (final dateDoc in expensesSnapshot.docs) {
        final dateId = dateDoc.id;
        _subscribeToDateItems(dateId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error subscribing to month dates: $e");
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, List<ExpenseItem>> getExpensesForType(ExpenseType type) {
    final Map<String, List<ExpenseItem>> result = {};

    for (final entry in _cachedExpenses.entries) {
      final filtered = entry.value.where((item) => item.type == type).toList();

      if (filtered.isNotEmpty) {
        result[entry.key] = filtered;
      }
    }

    return result;
  }

  double getTotalForDateByType(String dateId, ExpenseType type) {
    final items = _cachedExpenses[dateId] ?? [];
    return items.where((i) => i.type == type).fold(0.0, (s, i) => s + i.amount);
  }

  double getMonthTotalForType(ExpenseType type) {
    double total = 0;

    for (final items in _cachedExpenses.values) {
      for (final item in items) {
        if (item.type == type) {
          total += item.amount;
        }
      }
    }
    return total;
  }

  /// Subscribe to items for a specific date
  void _subscribeToDateItems(String dateId) {
    // Cancel existing subscription if any
    _dateSubscriptions[dateId]?.cancel();

    if (kDebugMode) {
      print("🔍 Subscribing to items for: $dateId");
    }

    final subscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(dateId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            // Update cache for this date
            if (snapshot.docs.isEmpty) {
              // Remove date from cache if no items
              _cachedExpenses.remove(dateId);
            } else {
              final items = snapshot.docs.map((doc) {
                return ExpenseItem.fromFirestore(doc.id, doc.data(), dateId);
              }).toList();

              _cachedExpenses[dateId] = items;
            }

            if (kDebugMode) {
              print(
                "✅ Updated cache for $dateId: ${snapshot.docs.length} items",
              );
            }

            notifyListeners();
          },
          onError: (error) {
            if (kDebugMode) {
              print("❌ Stream error for $dateId: $error");
            }
          },
        );

    _dateSubscriptions[dateId] = subscription;
  }

  /// Cancel all active subscriptions
  void _cancelAllSubscriptions() {
    if (kDebugMode) {
      print("🔌 Cancelling ${_dateSubscriptions.length} subscriptions");
    }

    for (final subscription in _dateSubscriptions.values) {
      subscription.cancel();
    }
    _dateSubscriptions.clear();
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔄 REFRESH FUNCTIONALITY
  // ═══════════════════════════════════════════════════════════════

  /// Manually refresh the current month
  Future<void> refresh() async {
    if (_currentMonth.isEmpty) return;

    if (kDebugMode) {
      print("🔄 Refreshing month: $_currentMonth");
    }

    await setMonth(_currentMonth);
  }

  /// Check for new dates in the current month and subscribe to them
  Future<void> checkForNewDates() async {
    if (_currentMonth.isEmpty) return;

    try {
      final expensesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .where(
            FieldPath.documentId,
            isGreaterThanOrEqualTo: '$_currentMonth-01',
          )
          .where(FieldPath.documentId, isLessThan: '$_currentMonth-32')
          .get();

      for (final dateDoc in expensesSnapshot.docs) {
        final dateId = dateDoc.id;

        // Subscribe if not already subscribed
        if (!_dateSubscriptions.containsKey(dateId)) {
          if (kDebugMode) {
            print("🆕 Found new date: $dateId");
          }
          _subscribeToDateItems(dateId);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error checking for new dates: $e");
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🧮 UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Get all dates in the month (sorted)
  List<String> get allDates {
    final dates = _cachedExpenses.keys.toList();
    dates.sort((a, b) => b.compareTo(a)); // Newest first
    return dates;
  }

  /// Get expenses grouped by expense type
  Map<String, double> get expensesByType {
    final Map<String, double> typeMap = {'saving': 0, 'needed': 0, 'luxury': 0};

    for (final items in _cachedExpenses.values) {
      for (final item in items) {
        typeMap[item.type.name] = (typeMap[item.type.name] ?? 0) + item.amount;
      }
    }

    return typeMap;
  }

  /// Get expenses grouped by transaction type
  Map<String, double> get expensesByTransactionType {
    final Map<String, double> transactionMap = {'cash': 0, 'upi': 0, 'card': 0};

    for (final items in _cachedExpenses.values) {
      for (final item in items) {
        final transactionType = item.transactionType;
        transactionMap[transactionType] =
            (transactionMap[transactionType] ?? 0) + item.amount;
      }
    }

    return transactionMap;
  }

  /// Clear all data and subscriptions
  void clear() {
    _cancelAllSubscriptions();
    _cachedExpenses.clear();
    _currentMonth = '';
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelAllSubscriptions();
    super.dispose();
  }
}

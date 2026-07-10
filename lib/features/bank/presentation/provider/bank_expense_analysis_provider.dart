import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../expense/data/model/expense_items.dart';
import '../../data/model/bank_model.dart';

class BankExpenseAnalysis {
  final String bankId;
  final String bankName;
  final double totalExpense;
  final int transactionCount;
  final List<ExpenseItem> expenses;

  BankExpenseAnalysis({
    required this.bankId,
    required this.bankName,
    required this.totalExpense,
    required this.transactionCount,
    required this.expenses,
  });
}

class BankAnalysisProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // 🔹 Date Selection
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String get selectedMonthId => DateFormat('yyyy-MM').format(_selectedDate);
  String get selectedYear => DateFormat('yyyy').format(_selectedDate);
  int get selectedMonth => _selectedDate.month;

  // 🔹 Analysis Data
  Map<String, BankExpenseAnalysis> _bankAnalysis = {};
  BankExpenseAnalysis? _cashAnalysis;
  BankExpenseAnalysis? _unknownAnalysis;

  Map<String, BankExpenseAnalysis> get bankAnalysis => _bankAnalysis;
  BankExpenseAnalysis? get cashAnalysis => _cashAnalysis;
  BankExpenseAnalysis? get unknownAnalysis => _unknownAnalysis;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double get totalMonthExpense {
    double total = 0;

    _bankAnalysis.values.forEach((analysis) {
      total += analysis.totalExpense;
    });

    if (_cashAnalysis != null) {
      total += _cashAnalysis!.totalExpense;
    }

    if (_unknownAnalysis != null) {
      total += _unknownAnalysis!.totalExpense;
    }

    return total;
  }

  int get totalTransactions {
    int count = 0;

    for (var analysis in _bankAnalysis.values) {
      count += analysis.transactionCount;
    }

    if (_cashAnalysis != null) {
      count += _cashAnalysis!.transactionCount;
    }

    if (_unknownAnalysis != null) {
      count += _unknownAnalysis!.transactionCount;
    }

    return count;
  }

  // 🔹 Initialize with specific bank
  Future<void> initialize(BankModel bank) async {
    await fetchAnalysis(bank);
  }

  // 🔹 Change Month
  void setMonth(int month) {
    final newDate = DateTime(_selectedDate.year, month, 1);
    if (_selectedDate != newDate) {
      _selectedDate = newDate;
      notifyListeners();
    }
  }

  // 🔹 Change Year
  void setYear(int year) {
    final newDate = DateTime(year, _selectedDate.month, 1);
    if (_selectedDate != newDate) {
      _selectedDate = newDate;
      notifyListeners();
    }
  }

  // 🔹 Navigate to previous month
  void previousMonth() {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    notifyListeners();
  }

  // 🔹 Navigate to next month
  void nextMonth() {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    notifyListeners();
  }

  // 🔹 Reset to current month
  void resetToCurrentMonth() {
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, 1);
    notifyListeners();
  }

  // 🔹 Main Analysis Fetch
  Future<void> fetchAnalysis(BankModel targetBank) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear previous data
      _bankAnalysis.clear();
      _cashAnalysis = null;
      _unknownAnalysis = null;

      final monthStart = '$selectedMonthId-01';
      final monthEnd = '$selectedMonthId-32'; // Covers all days in month

      if (kDebugMode) {
        print('🔍 Fetching analysis for ${targetBank.bankName} ($selectedMonthId)');
        print('   Range: $monthStart to $monthEnd');
      }

      // Get all expense dates for this month
      final expenseDatesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: monthStart)
          .where(FieldPath.documentId, isLessThan: monthEnd)
          .get();

      if (kDebugMode) {
        print('📅 Found ${expenseDatesSnapshot.docs.length} expense dates');
      }

      // Storage for categorized expenses
      final Map<String, List<ExpenseItem>> bankExpenses = {};
      final List<ExpenseItem> cashExpenses = [];
      final List<ExpenseItem> unknownExpenses = [];

      // Fetch items for each date
      for (final dateDoc in expenseDatesSnapshot.docs) {
        final dateId = dateDoc.id;

        final itemsSnapshot = await dateDoc.reference
            .collection('items')
            .orderBy('createdAt', descending: true)
            .get();

        if (kDebugMode) {
          print('📦 Date $dateId has ${itemsSnapshot.docs.length} items');
        }

        for (final itemDoc in itemsSnapshot.docs) {
          final expense = ExpenseItem.fromFirestore(
            itemDoc.id,
            itemDoc.data(),
            dateId,
          );

          final transactionType = expense.transactionType;

          if (kDebugMode) {
            print('   💳 ${expense.title}: ₹${expense.amount} (type: $transactionType)');
          }

          // Categorize by transaction type
          if (transactionType.isEmpty || transactionType == 'null') {
            // Handle empty/missing transaction type
            unknownExpenses.add(expense);
          } else if (transactionType == 'cash') {
            cashExpenses.add(expense);
          } else {
            // Bank transaction
            bankExpenses.putIfAbsent(transactionType, () => []).add(expense);
          }
        }
      }

      // 🔹 Build Analysis for Target Bank
      if (bankExpenses.containsKey(targetBank.id)) {
        final expenses = bankExpenses[targetBank.id]!;
        final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

        _bankAnalysis[targetBank.id] = BankExpenseAnalysis(
          bankId: targetBank.id,
          bankName: targetBank.bankName,
          totalExpense: total,
          transactionCount: expenses.length,
          expenses: expenses,
        );

        if (kDebugMode) {
          print('🏦 ${targetBank.bankName}: ₹$total (${expenses.length} transactions)');
        }
      }

      // 🔹 Build Cash Analysis
      if (cashExpenses.isNotEmpty) {
        final total = cashExpenses.fold<double>(0, (sum, e) => sum + e.amount);
        _cashAnalysis = BankExpenseAnalysis(
          bankId: 'cash',
          bankName: 'Cash',
          totalExpense: total,
          transactionCount: cashExpenses.length,
          expenses: cashExpenses,
        );

        if (kDebugMode) {
          print('💵 Cash: ₹$total (${cashExpenses.length} transactions)');
        }
      }

      // 🔹 Build Unknown Analysis
      if (unknownExpenses.isNotEmpty) {
        final total = unknownExpenses.fold<double>(0, (sum, e) => sum + e.amount);
        _unknownAnalysis = BankExpenseAnalysis(
          bankId: 'unknown',
          bankName: 'Unknown Source',
          totalExpense: total,
          transactionCount: unknownExpenses.length,
          expenses: unknownExpenses,
        );

        if (kDebugMode) {
          print('❓ Unknown: ₹$total (${unknownExpenses.length} transactions)');
        }
      }

      if (kDebugMode) {
        print('✅ Analysis complete: ₹$totalMonthExpense total ($totalTransactions transactions)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching bank analysis: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Get percentage for a specific analysis
  double getPercentage(double amount) {
    if (totalMonthExpense == 0) return 0;
    return (amount / totalMonthExpense) * 100;
  }

  String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    // Clean up resources
    _bankAnalysis.clear();
    _cashAnalysis = null;
    _unknownAnalysis = null;
    super.dispose();
  }
}
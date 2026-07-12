

import 'dart:async';

import 'package:expence_app/features/bank/presentation/provider/bank_provider.dart';
import 'package:expence_app/shared/providers/expense_type_selector_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/dialogs/app_loader_dialog.dart';
import '../../../../shared/dialogs/category_dialog.dart';
import '../../../../shared/dialogs/insufficient_balance_dialog.dart';
import '../../../../shared/providers/auto_complete_key_provider.dart';
import '../../../bank/data/model/bank_model.dart';

import '../../../../shared/enums/expense_type.dart';
import '../../../../shared/models/month_stats.dart';
import '../../../../shared/models/year_stats.dart';
import '../../data/model/expense_items.dart';
import '../../data/model/expense_model.dart';
import '../../domain/repository/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier implements AutoCompleteProvider,ExpenseTypeProvider {
  // 🔹 Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String get currentMonth => DateFormat('yyyy-MM').format(DateTime.now());

  bool get isCashTransaction =>
      _selectedTransaction == null || _selectedTransaction!.id == 'cash';

  String get currentBankMonthId => DateFormat('yyyy-MM').format(_selectedDate);

  ExpenseType _selectedType = ExpenseType.luxury;

  ExpenseType get selectedType => _selectedType;

  int _autoCompleteKey = 0;

  int get autoCompleteKey => _autoCompleteKey;

  String get currentYear => DateFormat('yyyy').format(DateTime.now());

  static const _kTransactionTypeKey = 'selected_transaction_type';

  // 🔹 Auth UID (SAFE)
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  BankModel? _selectedTransaction = cashBank;

  BankModel? get selectedTransaction => _selectedTransaction;

  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedDate.year == now.year && selectedDate.month == now.month;
  }

  // 🔹 Selected Date
  DateTime _selectedDate = DateTime.now();

  DateTime get selectedDate => _selectedDate;

  String _selectedYear = DateTime.now().year.toString();

  String get selectedYear => _selectedYear;

  int _selectedMonth = DateTime.now().month;

  int get selectedMonth => _selectedMonth;

  // 🔹 Repository (ONLY this talks to data — no FirebaseFirestore here)
  final ExpenseRepository _repository;

  // 🔧 FIXED: Renamed to currentDateId for clarity
  String get currentDateId => DateFormat('yyyy-MM-dd').format(_selectedDate);

  List<ExpenseItem> _cachedExpenses = [];

  List<ExpenseItem> get cachedExpenses => _cachedExpenses;

  String monthFromInt(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    if (month < 1 || month > 12) return 'Invalid month';
    return months[month - 1];
  }

  // Stream subscription
  StreamSubscription<List<ExpenseItem>>? _expenseSubscription;

  // Loading state
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  ExpenseProvider({required ExpenseRepository repository})
      : _repository = repository {
    _init();
  }

  // 🔧 NEW: Helper method to get date ID from any DateTime
  String getDateId(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> setTransactionType(BankModel type) async {
    _selectedTransaction = type;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTransactionTypeKey, type.id);
  }

  Future<void> restoreTransactionTypeFromBanks(List<BankModel> banks) async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_kTransactionTypeKey);

    // Default → cash
    if (savedId == null || savedId == 'cash') {
      _selectedTransaction = cashBank;
      notifyListeners();
      return;
    }

    try {
      final bank = banks.firstWhere(
            (b) => b.id == savedId,
        orElse: () => cashBank,
      );

      _selectedTransaction = bank;
    } catch (_) {
      _selectedTransaction = cashBank;
    }

    notifyListeners();
  }

  // 🔹 Select Date
  void setSelectedDate(DateTime date) {
    if (_selectedDate != date) {
      _selectedDate = date;
      _cachedExpenses = [];
      _subscribeToExpenses();
      notifyListeners();
    }
  }



  Future<void> _init() async {
    _initStream();
  }

  void setExpenseType(ExpenseType type) {
    _selectedType = type;
    notifyListeners();
  }

  void setYear(String year) {
    _selectedYear = year;
    notifyListeners();
  }

  void setMonth(int month) {
    _selectedMonth = month;
    notifyListeners();
  }

  /// 🔹 Expense total for year
  double getYearExpense(List<ExpenseDay> days) {
    return days
        .where((d) => d.dateId.startsWith(_selectedYear))
        .fold(0.0, (s, d) => s + d.total);
  }

  Future<bool> validateAndPrepareBankTransaction({
    required BuildContext context,
    required String bankId,
    required DateTime selectedDate,
    required double expenseAmount,
    required String bankName,
  }) async {
    final bankMonthId = DateFormat('yyyy-MM').format(selectedDate);

    // 1️⃣ Ensure month exists (returns result)
    final monthReady = await context
        .read<BankProvider>()
        .ensureBankMonthExistsWithDialog(
      context: context,
      bankId: bankId,
      monthId: bankMonthId,
    );

    if (!monthReady) return false;

    // 🔧 FIXED: Read from the specific month document instead of the parent bank doc
    final available = await _repository.getBankMonthBalance(
      uid: uid,
      bankId: bankId,
      monthId: bankMonthId,
    );

    if (available == null) return false;

    // 3️⃣ Final balance check
    if (available < expenseAmount) {
      AppLoader.hide();
      await InsufficientBalanceDialog.show(
        context,
        available: available,
        requiredAmount: expenseAmount,
        bankName: bankName,
      );
      return false;
    }

    return true;
  }

  // 🔹 Add Expense
  Future<void> addExpense(BuildContext context) async {
    AppLoader.show(context, message: 'Saving expense...');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppLoader.hide();
      return;
    }

    final title = titleController.text.trim();
    final amount = double.tryParse(
      amountController.text.replaceAll(',', '').trim(),
    );
    final desc = descriptionController.text.trim();

    if (title.isEmpty || amount == null || amount <= 0) {
      AppLoader.hide();
      return;

    }

    // 🔒 HARD BANK VALIDATION (UX pre-check; authoritative check happens
    // again inside the repository's transaction)
    if (!isCashTransaction) {
      final canProceed = await validateAndPrepareBankTransaction(
        context: context,
        bankId: _selectedTransaction!.id,
        selectedDate: _selectedDate,
        expenseAmount: amount,
        bankName: _selectedTransaction!.bankName,
      );

      // ❌ STOP if bank / month / balance invalid
      if (!canProceed) {
        AppLoader.hide();
        return;
      }
    }

    try {
      await _repository.addExpense(
        uid: uid,
        dateId: currentDateId,
        title: title,
        amount: amount,
        description: desc,
        expenseTypeName: _selectedType.name,
        transactionTypeId: _selectedTransaction?.id,
        itemCreatedAt: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          DateTime.now().hour,
          DateTime.now().minute,
        ),
      );

      clearForm();

      AppLoader.hide();

      if (kDebugMode) {
        print("⚡ Expense added instantly for $currentDateId");
      }
    } catch (e) {
      AppLoader.hide();
      debugPrint("❌ Add expense failed: $e");
    }
  }





  Future<void> editExpense({
    required BuildContext context,
    required String docId,
    required double oldAmount,
    required ExpenseType oldType,
    required DateTime oldDate,
    required String? oldTransactionTypeId,
  }) async {
    final title = titleController.text.trim();
    final newAmount = double.tryParse(
      amountController.text.replaceAll(',', '').trim(),
    );
    final desc = descriptionController.text.trim();

    if (title.isEmpty || newAmount == null || newAmount <= 0) return;

    final newType = _selectedType;
    final newBank = _selectedTransaction; // may be cash

    try {
      await _repository.editExpense(
        uid: uid,
        docId: docId,
        oldAmount: oldAmount,
        oldTypeName: oldType.name,
        oldDate: oldDate,
        oldTransactionTypeId: oldTransactionTypeId,
        title: title,
        newAmount: newAmount,
        description: desc,
        newTypeName: newType.name,
        newTransactionTypeId: newBank?.id,
      );

      clearForm();

      if (kDebugMode) {
        print('✏️ Expense edited successfully (month-based bank sync)');
      }
    } catch (e) {
      debugPrint('❌ Edit expense failed: $e');
    }
  }

  void clearForm() {
    titleController.clear();
    amountController.clear();
    descriptionController.clear();
    _autoCompleteKey++; // Force rebuild
    _selectedType = ExpenseType.luxury; // Reset to default
    notifyListeners();
  }

  void _initStream() {
    if (FirebaseAuth.instance.currentUser == null) {
      if (kDebugMode) {
        print("❌ No authenticated user");
      }
      return;
    }

    _subscribeToExpenses();
  }

  void _subscribeToExpenses() {
    // Cancel previous subscription
    _expenseSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

    if (kDebugMode) {
      print("🔍 Subscribing to expenses for:");
      print("   User: $uid");
      print("   Date: $currentDateId");
    }

    _expenseSubscription = _repository
        .watchExpenses(uid: uid, dateId: currentDateId)
        .listen(
          (items) {
        _cachedExpenses = items;

        _isLoading = false;

        if (kDebugMode) {
          print(
            "✅ Loaded ${_cachedExpenses.length} expenses for $currentDateId",
          );
        }

        notifyListeners();
      },
      onError: (error) {
        if (kDebugMode) {
          print("❌ Stream error: $error");
        }
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Calculate total from cached data
  double get totalExpense {
    return _cachedExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Get expense by ID from cache
  ExpenseItem? getExpenseById(String id) {
    try {
      return _cachedExpenses.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // Manually refresh (for edge cases)
  Future<void> refresh() async {
    _subscribeToExpenses();
  }

  // 🔹 Delete Expense - ✅ ALREADY CORRECT!
  // This method was already using the expense's actual date correctly
  Future<void> deleteExpense({
    required String docId,
    required double amount,
    required ExpenseType type,
    required String dateId,
    required String? bankId, // 👈 IMPORTANT
  }) async {
    try {
      await _repository.deleteExpense(
        uid: uid,
        docId: docId,
        amount: amount,
        typeName: type.name,
        dateId: dateId,
        bankId: bankId,
      );

      if (kDebugMode) {
        print("🗑️ Expense deleted & bank restored: $docId");
      }
    } catch (e) {
      debugPrint("❌ Delete expense failed: $e");
    }
  }

  Future<List<ExpenseDay>> getAllExpenseDays() async {
    return _repository.getAllExpenseDays(uid: uid);
  }

  Map<String, List<ExpenseDay>> groupByMonthAllYears(List<ExpenseDay> days) {
    final Map<String, List<ExpenseDay>> map = {};

    for (final d in days) {
      final monthKey = d.dateId.substring(0, 7); // yyyy-MM
      map.putIfAbsent(monthKey, () => []).add(d);
    }

    return map;
  }

  Future<Map<String, List<ExpenseItem>>> fetchMonthExpenses(
      String monthKey,
      // yyyy-MM format (e.g., '2025-01')
      ) async {
    final grouped = await _repository.getMonthExpenses(
      uid: uid,
      monthKey: monthKey,
    );

    if (kDebugMode) {
      print("📊 Fetched expenses for $monthKey: ${grouped.length} dates");
    }

    return grouped;
  }

  Future<YearStats?> getYearStats() async {
    return _repository.getYearStats(uid: uid, year: selectedYear);
  }

  Future<List<MonthStats>> getMonthStatsForSelectedYear() async {
    return _repository.getMonthStatsForYear(uid: uid, year: selectedYear);
  }

  Future<MonthStats?> getMonthStatsByMonth(String month) async {
    return _repository.getMonthStatsByMonth(
      uid: uid,
      year: selectedYear,
      month: month,
    );
  }

  Future<double> getTotalForDate(String dateId) async {
    final total = await _repository.getTotalForDate(uid: uid, dateId: dateId);

    if (kDebugMode) {
      print("💰 Total for $dateId: $total");
    }

    return total;
  }

  Map<String, List<String>> groupDatesByMonth(List<String> dates) {
    final Map<String, List<String>> grouped = {};

    for (final date in dates) {
      final monthKey = date.substring(0, 7);
      grouped.putIfAbsent(monthKey, () => []).add(date);
    }

    return grouped;
  }

  Future<Map<String, List<ExpenseDay>>> getExpensesGroupedByMonthForType(
      ExpenseType type,
      ) async {
    return _repository.getExpensesGroupedByMonthForType(
      uid: uid,
      expenseTypeName: type.name,
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    _expenseSubscription?.cancel();
    super.dispose();
  }
}
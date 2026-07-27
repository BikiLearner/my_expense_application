import 'dart:async';

import 'package:expence_app/core/services/session_maganger.dart';
import 'package:expence_app/features/bank/domain/repository/bank_repository.dart';
import 'package:expence_app/features/bank/presentation/provider/bank_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/dialogs/app_loader_dialog.dart';
import '../../../../shared/dialogs/insufficient_balance_dialog.dart';
import '../../../../shared/enums/expense_type.dart';
import '../../../bank/data/model/bank_model.dart';
import '../../data/model/expense_items.dart';
import '../../data/model/expense_model.dart';
import '../../domain/repository/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  // 🔹 Controllers
  String _title = "";

  String get title => _title;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String get currentMonth => DateFormat('yyyy-MM').format(DateTime.now());

  bool get isCashTransaction =>
      _selectedTransaction == null || _selectedTransaction!.id == 'cash';

  String get currentBankMonthId => DateFormat('yyyy-MM').format(_selectedDate);

  ExpenseType _selectedType = ExpenseType.luxury;

  ExpenseType get selectedType => _selectedType;

  String get currentYear => DateFormat('yyyy').format(DateTime.now());

  static const _kTransactionTypeKey = 'selected_transaction_type';
  int _titleResetId = 0;

  int get titleResetId => _titleResetId;


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
  final BankRepository _bankRepository;

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

  ExpenseProvider({
    required ExpenseRepository repository,
    required BankRepository bankRepository,
  }) : _repository = repository,
       _bankRepository = bankRepository {
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

  void setTitle(String value) {
    _title = value;
    notifyListeners();
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



  void resetTitleField() {
    _title = '';
    _titleResetId++;
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

  String getMonthId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  Future<bool> validateAndPrepareBankTransaction({
    required BuildContext context,
    required String bankId,
    required DateTime selectedDate,
    required double expenseAmount,
    required String bankName,
  }) async {
    // 1️⃣ Ensure month exists (returns result)
    final monthReady = await context
        .read<BankProvider>()
        .ensureBankMonthExistsWithDialog(context: context, bankId: bankId);

    if (!monthReady) return false;
    final available = await _bankRepository.getBankMonthBalance(bankId: bankId);
    // 🔧 FIXED: Read from the specific month document instead of the parent bank doc

    if (available == null) return false;

    // 3️⃣ Final balance check
    if (available < expenseAmount) {
      AppLoader.hide();
      if (!context.mounted) return false;
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

    final user = SessionManager.instance.user;
    if (user == null) {
      AppLoader.hide();
      return;
    }

    final title = _title.trim();
    final amount = double.tryParse(
      amountController.text.replaceAll(',', '').trim(),
    );
    final desc = descriptionController.text.trim();

    if (title.isEmpty || amount == null || amount <= 0) {
      AppLoader.hide();
      return;
    }

    if (!isCurrentMonth) {
      setTransactionType(cashBank);
    }

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

      if (kDebugMode) {
        print("⚡ Expense added instantly for $currentDateId");
      }
    } catch (e) {
      debugPrint("❌ Add expense failed: $e");
    } finally {
      AppLoader.hide();
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
    final title = _title.trim();
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
    _title = "";
    amountController.clear();
    descriptionController.clear();
    _selectedType = ExpenseType.luxury; // Reset to default
    resetTitleField();
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
    return _repository.getAllExpenseForEveryMonth(uid: uid);
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    _expenseSubscription?.cancel();
    super.dispose();
  }
}

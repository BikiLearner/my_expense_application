// 🔧 CORRECTED: Changed dateId getter to currentDateId for clarity
// This prevents confusion between current selected date and expense dates

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expence_app/features/bank/presentation/provider/bank_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/models/income_entry.dart';
import '../../../../shared/models/month_stats.dart';
import '../../../../shared/models/year_stats.dart';
import '../../../bank/data/model/bank_model.dart';

import '../../../../shared/enums/expense_type.dart';
import '../../data/model/expense_items.dart';
import '../../data/model/expense_model.dart';
import '../../domain/repository/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool _isBalanceDialogOpen = false;


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

  // 🔹 Firestore
  String _selectedYear = DateTime.now().year.toString();

  String get selectedYear => _selectedYear;

  int _selectedMonth = DateTime.now().month;

  int get selectedMonth => _selectedMonth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔧 FIXED: Renamed to currentDateId for clarity
  String get currentDateId => DateFormat('yyyy-MM-dd').format(_selectedDate);

  List<ExpenseItem> _cachedExpenses = [];

  List<ExpenseItem> get cachedExpenses => _cachedExpenses;

  // Current selected date

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
  StreamSubscription<QuerySnapshot>? _expenseSubscription;

  // Loading state
  bool _isLoading = false;

  bool get isLoading => _isLoading;


  final ExpenseRepository _repository;
  ExpenseProvider({
    required ExpenseRepository repository,
  }) : _repository = repository {
    _init();
  }

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

  List<String> cachedCategories = [];

  Future<void> _init() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await fetchCategories();
    }
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

  double getYearIncome(List<IncomeEntry> incomes) {
    return incomes
        .where((i) => i.year == _selectedYear)
        .fold(0.0, (s, i) => s + i.amount);
  }

  Future<bool> validateAndPrepareBankTransaction({
    required BuildContext context,
    required String bankId,
    required DateTime selectedDate,
    required double expenseAmount,
    required String bankName,
  }) async {
    final bankRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('bank')
        .doc(bankId);

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
    final bankMonthRef = bankRef.collection('monthAmount').doc(bankMonthId);
    final bankMonthSnap = await bankMonthRef.get();

    if (!bankMonthSnap.exists) return false;

    final available = (bankMonthSnap.data()?['currentAmount'] ?? 0).toDouble();

    // 3️⃣ Final balance check
    if (available < expenseAmount) {
      await showInsufficientBalanceDialog(
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final title = titleController.text.trim();
    final amount = double.tryParse(
      amountController.text.replaceAll(',', '').trim(),
    );
    final desc = descriptionController.text.trim();

    if (title.isEmpty || amount == null || amount <= 0) return;
    // 🔒 HARD BANK VALIDATION
    if (!isCashTransaction) {
      final canProceed = await validateAndPrepareBankTransaction(
        context: context,
        bankId: _selectedTransaction!.id,
        selectedDate: _selectedDate,
        expenseAmount: amount,
        bankName: _selectedTransaction!.bankName,
      );

      // ❌ STOP if bank / month / balance invalid
      if (!canProceed) return;
    }
    bool _ = true;

    try {
      final userRef = _firestore.collection('users').doc(uid);
      // 🔧 FIXED: Use currentDateId instead of dateId
      final dateRef = userRef.collection('expenses').doc(currentDateId);
      final year = currentDateId.substring(0, 4);
      final month = currentDateId.substring(0, 7);

      final batch = _firestore.batch();
      final yearRef = userRef.collection('year_stats').doc(year);
      final monthRef = yearRef.collection('months').doc(month);

      // 1️⃣ Update date total
      batch.set(dateRef, {
        'date': currentDateId,
        'total': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2️⃣ Add expense item
      batch.set(dateRef.collection('items').doc(), {
        'title': title,
        'amount': amount,
        'description': desc,
        'type': _selectedType.name,
        'transactionType': _selectedTransaction?.id,
        'createdAt': Timestamp.fromDate(
          DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            DateTime.now().hour,
            DateTime.now().minute,
          ),
        ),
      });

      // 3️⃣ Update grand total
      batch.set(userRef, {
        'grandTotal': FieldValue.increment(amount),
      }, SetOptions(merge: true));

      // 4️⃣ Year grand total
      batch.set(yearRef, {
        'grandTotal': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 5️⃣ Month type totals + month total
      batch.set(monthRef, {
        'month': month,
        _selectedType.name: FieldValue.increment(amount),
        'grandTotal': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!isCashTransaction) {
        final bankId = _selectedTransaction!.id;

        final bankRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('bank')
            .doc(bankId);

        final bankMonthId = DateFormat('yyyy-MM').format(_selectedDate);

        final bankMonthRef = bankRef.collection('monthAmount').doc(bankMonthId);

        try {
          await _firestore.runTransaction((tx) async {
            // 🔁 MUST read inside transaction
            final bankSnap = await tx.get(bankRef);
            final bankMonthSnap = await tx.get(bankMonthRef);

            // ❌ Bank deleted → HARD STOP
            if (!bankSnap.exists) {
              throw Exception('Bank not found during deduction');
            }

            // ❌ Month missing → HARD STOP
            if (!bankMonthSnap.exists) {
              throw Exception('Bank month not found during deduction');
            }

            final currentBalance = (bankMonthSnap.data()?['currentAmount'] ?? 0)
                .toDouble();

            // ❌ Balance changed meanwhile → HARD STOP
            if (currentBalance < amount) {
              throw Exception('Insufficient balance during transaction');
            }

            tx.update(bankMonthRef, {
              'currentAmount': FieldValue.increment(-amount),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          });
        } catch (e) {
          debugPrint('❌ Bank deduction failed: $e');
          return; // ⛔ DO NOT COMMIT EXPENSE BATCH
        }
      }

      await batch.commit();

      clearForm();

      if (kDebugMode) {
        print("⚡ Expense added instantly for $currentDateId");
      }
    } catch (e) {
      debugPrint("❌ Add expense failed: $e");
    }
  }

  Future<void> showInsufficientBalanceDialog(
    BuildContext context, {
    required double available,
    required double requiredAmount,
    required String bankName,
  }) async {
    if (_isBalanceDialogOpen) return; // 🚫 prevent stacking
    _isBalanceDialogOpen = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),

        title: Row(
          children: const [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              'Aukat Alert 🚨',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Bhai ruk ja 😶‍🌫️\n'
              'Yeh expense thoda zyada ho raha hai.',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3C3C3C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bankName,
                    style: const TextStyle(
                      color: Color(0xFF64FFDA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wallet mein: ₹${available.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Kharcha chahiye: ₹${requiredAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            const Text(
              '😌 Tip: Cash use kar le ya amount kam kar.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),

        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64FFDA),
                foregroundColor: const Color(0xFF121212),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // ✅ ALWAYS WORKS
              },
              child: const Text(
                'Samajh gaya 😅',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );

    _isBalanceDialogOpen = false; // ✅ reset after close
  }

  Future<void> fetchCategories() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('categories')
          .orderBy('createdAt')
          .get();

      cachedCategories = snapshot.docs
          .map((doc) => (doc.data()['title'] as String).trim())
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();

      if (kDebugMode) {
        print("📂 Categories loaded: $cachedCategories");
      }

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Failed to fetch categories: $e");
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
    final diff = newAmount - oldAmount;

    final dateId = getDateId(oldDate);
    final year = DateFormat('yyyy').format(oldDate);
    final monthId = DateFormat('yyyy-MM').format(oldDate);

    final userRef = _firestore.collection('users').doc(uid);
    final dateRef = userRef.collection('expenses').doc(dateId);
    final itemRef = dateRef.collection('items').doc(docId);
    final yearRef = userRef.collection('year_stats').doc(year);
    final monthRef = yearRef.collection('months').doc(monthId);

    try {
      final batch = _firestore.batch();

      batch.update(itemRef, {
        'title': title,
        'amount': newAmount,
        'description': desc,
        'type': newType.name,
        'transactionType': newBank?.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (diff != 0) {
        batch.set(dateRef, {
          'total': FieldValue.increment(diff),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        batch.set(userRef, {
          'grandTotal': FieldValue.increment(diff),
        }, SetOptions(merge: true));

        batch.set(yearRef, {
          'grandTotal': FieldValue.increment(diff),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (oldType == newType) {
        if (diff != 0) {
          batch.set(monthRef, {
            newType.name: FieldValue.increment(diff),
            'grandTotal': FieldValue.increment(diff),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } else {
        batch.set(monthRef, {
          oldType.name: FieldValue.increment(-oldAmount),
          newType.name: FieldValue.increment(newAmount),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      await _firestore.runTransaction((tx) async {
        // 🟡 SAME BANK
        if (oldTransactionTypeId == newBank?.id &&
            oldTransactionTypeId != null &&
            oldTransactionTypeId != 'cash') {
          if (diff == 0) return;

          final monthRef = userRef
              .collection('bank')
              .doc(oldTransactionTypeId)
              .collection('monthAmount')
              .doc(monthId);

          final monthSnap = await tx.get(monthRef);
          if (!monthSnap.exists) return;

          final current = (monthSnap.data()?['currentAmount'] ?? 0).toDouble();

          if (diff > 0 && current < diff) {
            throw Exception('Insufficient balance during edit');
          }

          tx.update(monthRef, {
            'currentAmount': FieldValue.increment(-diff),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        // 🔵 BANK CHANGED
        else {
          // ➕ RETURN TO OLD BANK
          if (oldTransactionTypeId != null && oldTransactionTypeId != 'cash') {
            final oldMonthRef = userRef
                .collection('bank')
                .doc(oldTransactionTypeId)
                .collection('monthAmount')
                .doc(monthId);

            final oldMonthSnap = await tx.get(oldMonthRef);
            if (oldMonthSnap.exists) {
              tx.update(oldMonthRef, {
                'currentAmount': FieldValue.increment(oldAmount),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }

          // ➖ DEDUCT FROM NEW BANK
          if (newBank?.id != null && newBank!.id != 'cash') {
            final newMonthRef = userRef
                .collection('bank')
                .doc(newBank.id)
                .collection('monthAmount')
                .doc(monthId);

            final newMonthSnap = await tx.get(newMonthRef);
            if (!newMonthSnap.exists) {
              throw Exception('Target bank month missing');
            }

            final current = (newMonthSnap.data()?['currentAmount'] ?? 0)
                .toDouble();

            if (current < newAmount) {
              throw Exception('Insufficient balance in new bank');
            }

            tx.update(newMonthRef, {
              'currentAmount': FieldValue.increment(-newAmount),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      clearForm();

      if (kDebugMode) {
        print('✏️ Expense edited successfully (month-based bank sync)');
      }
    } catch (e) {
      debugPrint('❌ Edit expense failed: $e');
    }
  }

  void hideLoadingDialog(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> showLoadingDialog(
    BuildContext context, {
    String message = 'Processing...',
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false, // ❌ user cannot close
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF64FFDA),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void clearForm() {
    titleController.clear();
    amountController.clear();
    descriptionController.clear();
    _autoCompleteKey++; // Force rebuild
    _selectedType = ExpenseType.luxury; // Reset to default
    notifyListeners();
  }

  Future<void> addIncome({
    required double amount,
    required String source,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || amount <= 0) return;

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final monthRef = userRef.collection('incomes').doc(currentMonth);

      final batch = _firestore.batch();

      // 1️⃣ Add income item
      batch.set(monthRef.collection('items').doc(), {
        'amount': amount,
        'source': source,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2️⃣ Update monthly total
      batch.set(monthRef, {
        'month': currentMonth,
        'total': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      if (kDebugMode) {
        print("💰 Income added: ₹$amount");
      }
    } catch (e) {
      debugPrint("❌ Add income failed: $e");
    }
  }

  Future<void> deleteIncome({
    required String monthId,
    required String itemId,
    required double amount,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final monthRef = userRef.collection('incomes').doc(monthId);
      final itemRef = monthRef.collection('items').doc(itemId);

      final batch = _firestore.batch();

      // 1️⃣ Delete income item
      batch.delete(itemRef);

      // 2️⃣ Decrement monthly total
      batch.set(monthRef, {
        'total': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      if (kDebugMode) {
        print("🗑️ Income deleted: ₹$amount from $monthId");
      }
    } catch (e) {
      debugPrint("❌ Delete income failed: $e");
    }
  }

  Future<double> getYearIncomeFromFirestore(String year) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('incomes')
          .get();

      double total = 0;

      for (final doc in snapshot.docs) {
        if (doc.id.startsWith(year)) {
          total += (doc.data()['total'] ?? 0).toDouble();
        }
      }

      return total;
    } catch (e) {
      return 0;
    }
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

    _expenseSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(currentDateId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _cachedExpenses = snapshot.docs
                .map(
                  (doc) => ExpenseItem.fromFirestore(
                    doc.id,
                    doc.data(),
                    currentDateId,
                  ),
                )
                .toList();

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

  // Update selected date and refresh stream

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
      final userRef = _firestore.collection('users').doc(uid);
      final dateRef = userRef.collection('expenses').doc(dateId);

      final year = dateId.substring(0, 4);
      final month = dateId.substring(0, 7);

      final yearRef = userRef.collection('year_stats').doc(year);
      final monthRef = yearRef.collection('months').doc(month);

      // 🔹 STEP 1: Delete expense + stats (BATCH)
      final batch = _firestore.batch();

      batch.delete(dateRef.collection('items').doc(docId));

      batch.set(dateRef, {
        'total': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(userRef, {
        'grandTotal': FieldValue.increment(-amount),
      }, SetOptions(merge: true));

      batch.set(yearRef, {
        'grandTotal': FieldValue.increment(-amount),
      }, SetOptions(merge: true));

      batch.set(monthRef, {
        type.name: FieldValue.increment(-amount),
        'grandTotal': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      // 🔹 STEP 2: Restore bank balance (TRANSACTION)
      if (bankId != null && bankId != 'cash') {
        final bankRef = userRef.collection('bank').doc(bankId);
        final bankMonthRef = bankRef.collection('monthAmount').doc(month);

        await _firestore.runTransaction((tx) async {
          final bankSnap = await tx.get(bankRef);
          final bankMonthSnap = await tx.get(bankMonthRef);

          // ❌ Bank not found → skip
          if (!bankSnap.exists) return;

          // ❌ Month not found → skip
          if (!bankMonthSnap.exists) return;

          // 🔺 Delete expense = money BACK
          // tx.update(bankRef, {
          //   'currentAmount': FieldValue.increment(amount),
          // });

          tx.update(bankMonthRef, {
            'currentAmount': FieldValue.increment(amount),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
      }

      if (kDebugMode) {
        print("🗑️ Expense deleted & bank restored: $docId");
      }
    } catch (e) {
      debugPrint("❌ Delete expense failed: $e");
    }
  }

  Future<List<ExpenseDay>> getAllExpenseDays() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .get();

      return snapshot.docs.map((doc) {
        return ExpenseDay(
          dateId: doc.id,
          total: (doc.data()['total'] ?? 0).toDouble(),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error getting expense days: $e");
      }
      return [];
    }
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
    final Map<String, List<ExpenseItem>> grouped = {};

    try {
      // Get all expense dates for this month
      final expensesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$monthKey-01')
          .where(
            FieldPath.documentId,
            isLessThan: '$monthKey-32',
          ) // Covers all days
          .get();

      // Fetch items for each date
      for (final dateDoc in expensesSnapshot.docs) {
        final dateId = dateDoc.id;

        final itemsSnapshot = await dateDoc.reference.collection('items').get();

        if (itemsSnapshot.docs.isEmpty) continue;

        final items = itemsSnapshot.docs.map((itemDoc) {
          return ExpenseItem.fromFirestore(itemDoc.id, itemDoc.data(), dateId);
        }).toList();

        grouped[dateId] = items;
      }

      if (kDebugMode) {
        print("📊 Fetched expenses for $monthKey: ${grouped.length} dates");
      }

      return grouped;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error fetching month expenses: $e");
      }
      return {};
    }
  }

  Future<YearStats?> getYearStats() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('year_stats')
          .doc(selectedYear)
          .get();

      if (!doc.exists) return null;

      return YearStats.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      if (kDebugMode) {
        print("❌ Failed to fetch year stats: $e");
      }
      return null;
    }
  }

  Future<List<MonthStats>> getMonthStatsForSelectedYear() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('year_stats')
          .doc(selectedYear)
          .collection('months')
          .orderBy('month')
          .get();

      return snapshot.docs
          .map((doc) => MonthStats.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print("❌ Failed to fetch month stats: $e");
      }
      return [];
    }
  }

  Future<MonthStats?> getMonthStatsByMonth(String month) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('year_stats')
          .doc(selectedYear)
          .collection('months')
          .doc(month)
          .get();

      if (!doc.exists) return null;

      return MonthStats.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      if (kDebugMode) {
        print("❌ Failed to fetch month stats ($month): $e");
      }
      return null;
    }
  }

  Future<double> getTotalForDate(String dateId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(dateId)
          .get();

      final total = (doc.data()?['total'] ?? 0).toDouble();

      if (kDebugMode) {
        print("💰 Total for $dateId: $total");
      }

      return total;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error getting total for $dateId: $e");
      }
      return 0;
    }
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
    final Map<String, List<ExpenseDay>> grouped = {};

    final datesSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .get();

    for (final dateDoc in datesSnapshot.docs) {
      final dateId = dateDoc.id;
      final monthKey = dateId.substring(0, 7);

      final itemsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(dateId)
          .collection('items')
          .where('type', isEqualTo: type.name)
          .get();

      if (itemsSnapshot.docs.isEmpty) continue;

      final total = itemsSnapshot.docs.fold<double>(
        0,
        (s, d) => s + (d.data()['amount'] as num).toDouble(),
      );

      final day = ExpenseDay(dateId: dateId, total: total);

      grouped.putIfAbsent(monthKey, () => []).add(day);
    }

    return grouped;
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    _expenseSubscription?.cancel();
    super.dispose();
  }

  Future<void> showAddCategoryDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Category',
          style: TextStyle(color: Colors.white),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: double.maxFinite,
              height: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g. Food, Travel, Rent',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (cachedCategories.isNotEmpty) ...[
                    const Text(
                      'Existing Categories',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: ListView.builder(
                        itemCount: cachedCategories.length,
                        itemBuilder: (context, index) {
                          final category = cachedCategories[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    await deleteCategory(category);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: const Color(0xFF121212),
            ),
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isEmpty) return;

              try {
                await _firestore
                    .collection('users')
                    .doc(uid)
                    .collection('categories')
                    .add({
                      'title': title,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                await fetchCategories();

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              } catch (e) {
                debugPrint('❌ Failed to add category: $e');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteCategory(String categoryTitle) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('categories')
          .where('title', isEqualTo: categoryTitle)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      await fetchCategories(); // refresh cache

      if (kDebugMode) {
        print('🗑️ Category deleted: $categoryTitle');
      }
    } catch (e) {
      debugPrint('❌ Failed to delete category: $e');
    }
  }
}

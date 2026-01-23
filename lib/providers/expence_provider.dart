// 🔧 CORRECTED: Changed dateId getter to currentDateId for clarity
// This prevents confusion between current selected date and expense dates

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../enums/expense_type.dart';
import '../enums/transaction_type_enum.dart';
import '../expense_model.dart';
import '../models/expense_items.dart';
import '../models/income_entry.dart';
import '../models/month_stats.dart';
import '../models/year_stats.dart';

class ExpenseProvider extends ChangeNotifier {
  // 🔹 Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String get currentMonth => DateFormat('yyyy-MM').format(DateTime.now());

  ExpenseType _selectedType = ExpenseType.luxury;
  ExpenseType get selectedType => _selectedType;

  int _autoCompleteKey = 0;
  int get autoCompleteKey => _autoCompleteKey;

  String get currentYear => DateFormat('yyyy').format(DateTime.now());

  // 🔹 Auth UID (SAFE)
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  TransactionTypeEnum _selectedTransaction =
      TransactionTypeEnum.cash; // ✅ default

  TransactionTypeEnum get selectedTransaction => _selectedTransaction;

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


  // 🔧 NEW: Helper method to get date ID from any DateTime
  String getDateId(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  void setTransactionType(TransactionTypeEnum type) {
    _selectedTransaction = type;
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

  ExpenseProvider() {
    _init();
  }

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

  // 🔹 Add Expense
  Future<void> addExpense() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final title = titleController.text.trim();
    final amount = double.tryParse(amountController.text.trim());
    final desc = descriptionController.text.trim();

    if (title.isEmpty || amount == null || amount <= 0) return;

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
      batch.set(
        dateRef,
        {
          'date': currentDateId,
          'total': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp()
        
},
        SetOptions(merge: true)
      );

      // 2️⃣ Add expense item
      batch.set(
        dateRef.collection('items').doc(),
        {
          'title': title,
          'amount': amount,
          'description': desc,
          'type': _selectedType.name,
          'transactionType': _selectedTransaction.name,
          'createdAt': Timestamp.fromDate(
            DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              DateTime.now().hour,
              DateTime.now().minute
            )
          )
        
}
      );

      // 3️⃣ Update grand total
      batch.set(
        userRef,
        {
          'grandTotal': FieldValue.increment(amount)
        
},
        SetOptions(merge: true)
      );

      // 4️⃣ Year grand total
      batch.set(
        yearRef,
        {
          'grandTotal': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp()
        
},
        SetOptions(merge: true)
      );

      // 5️⃣ Month type totals + month total
      batch.set(
        monthRef,
        {
          'month': month,
          _selectedType.name: FieldValue.increment(amount),
          'grandTotal': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp()
        
},
        SetOptions(merge: true)
      );

      await batch.commit();

      clearForm();

      if (kDebugMode) {
        print("⚡ Expense added instantly for $currentDateId");
      }
    } catch (e) {
      debugPrint("❌ Add expense failed: $e");
    }
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
    required String docId,
    required double oldAmount,
    required ExpenseType oldType,
    required DateTime oldDate
  }) async {
    final title = titleController.text.trim();
    final newAmount = double.tryParse(amountController.text.trim());
    final desc = descriptionController.text.trim();

    if (title.isEmpty || newAmount == null || newAmount <= 0) return;

    final newType = _selectedType;
    final newTransactionType = _selectedTransaction;
    final diff = newAmount - oldAmount;

    final year = DateFormat('yyyy').format(oldDate);
    final month = DateFormat('yyyy-MM').format(oldDate);
    // 🔧 FIXED: Use getDateId helper method
    final oldDateId = getDateId(oldDate);

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final dateRef = userRef.collection('expenses').doc(oldDateId);
      final itemRef = dateRef.collection('items').doc(docId);

      final yearRef = userRef.collection('year_stats').doc(year);
      final monthRef = yearRef.collection('months').doc(month);

      final batch = _firestore.batch();

      // 1️⃣ Update expense item
      batch.update(itemRef, {
        'title': title,
        'amount': newAmount,
        'description': desc,
        'type': newType.name,
        'transactionType': newTransactionType.name,
        'updatedAt': FieldValue.serverTimestamp()
      
});

      // 2️⃣ Update day total + user grand total
      if (diff != 0) {
        batch.set(
          dateRef,
          {
            'total': FieldValue.increment(diff),
            'updatedAt': FieldValue.serverTimestamp()
          
},
          SetOptions(merge: true)
        );

        batch.set(
          userRef,
          {
            'grandTotal': FieldValue.increment(diff)
          
},
          SetOptions(merge: true)
        );

        batch.set(
          yearRef,
          {
            'grandTotal': FieldValue.increment(diff)
          
},
          SetOptions(merge: true)
        );
      }

      // 3️⃣ Update month stats
      if (oldType == newType) {
        if (diff != 0) {
          batch.set(
            monthRef,
            {
              newType.name: FieldValue.increment(diff),
              'grandTotal': FieldValue.increment(diff),
              'updatedAt': FieldValue.serverTimestamp()
            
},
            SetOptions(merge: true)
          );
        }
      } else {
        batch.set(
          monthRef,
          {
            oldType.name: FieldValue.increment(-oldAmount),
            newType.name: FieldValue.increment(newAmount),
            'updatedAt': FieldValue.serverTimestamp()
          
},
          SetOptions(merge: true)
        );
      }

      await batch.commit();

      clearForm();

      if (kDebugMode) {
        print("✏️ Expense updated successfully: $docId");
      }
    } catch (e) {
      debugPrint("❌ Edit expense failed: $e");
    }
  }

  void clearForm() {
    titleController.clear();
    amountController.clear();
    descriptionController.clear();
    _autoCompleteKey++; // Force rebuild
    _selectedType = ExpenseType.luxury; // Reset to default
    _selectedTransaction = TransactionTypeEnum.cash;
    notifyListeners();
  }

  Future<void> addIncome({
    required double amount,
    required String source
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || amount <= 0) return;

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final monthRef = userRef.collection('incomes').doc(currentMonth);

      final batch = _firestore.batch();

      // 1️⃣ Add income item
      batch.set(
        monthRef.collection('items').doc(),
        {
          'amount': amount,
          'source': source,
          'createdAt': FieldValue.serverTimestamp()
        
}
      );

      // 2️⃣ Update monthly total
      batch.set(
        monthRef,
        {
          'month': currentMonth,
          'total': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp()
        
},
        SetOptions(merge: true)
      );

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
    required double amount
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
      batch.set(
        monthRef,
        {
          'total': FieldValue.increment(-amount),
          'updatedAt': FieldValue.serverTimestamp()
        
},
        SetOptions(merge: true)
      );

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
            .map((doc) => ExpenseItem.fromFirestore(doc.id, doc.data(),currentDateId))
            .toList();

        _isLoading = false;

        if (kDebugMode) {
          print("✅ Loaded ${_cachedExpenses.length} expenses for $currentDateId");
        }

        notifyListeners();
      },
      onError: (error) {
        if (kDebugMode) {
          print("❌ Stream error: $error");
        }
        _isLoading = false;
        notifyListeners();
      }
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


  Future<List<Map<String, dynamic>>> getAllExpensesForSearch() async {
    try {
      final List<Map<String, dynamic>> allExpenses = [];

      final datesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .get();

      for (var dateDoc in datesSnapshot.docs) {
        final dateId = dateDoc.id;

        final itemsSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .doc(dateId)
            .collection('items')
            .get();

        for (var item in itemsSnapshot.docs) {
          final data = item.data();
          allExpenses.add({
            'id': item.id,
            'dateId': dateId,
            'title': data['title'] ?? '',
            'amount': (data['amount'] ?? 0).toDouble(),
            'description': data['description'] ?? '',
            'createdAt': data['createdAt']
          
});
        }
      }

      allExpenses.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      if (kDebugMode) {
        print("📊 Fetched ${allExpenses.length} expenses for search");
      }

      return allExpenses;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error fetching all expenses: $e");
      }
      return [];
    }
  }

  // 🔹 Delete Expense - ✅ ALREADY CORRECT!
  // This method was already using the expense's actual date correctly
  Future<void> deleteExpense({
    required String docId,
    required double amount,
    required ExpenseType type,
    required String dateId // ✅ Uses expense's actual date
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      // 🔧 FIXED: Use getDateId helper with the expense's actual date
      final dateRef = userRef.collection('expenses').doc(dateId);


      final year = dateId.substring(0, 4);
      final month = dateId.substring(0, 7);

      final yearRef = userRef.collection('year_stats').doc(year);
      final monthRef = yearRef.collection('months').doc(month);

      final batch = _firestore.batch();

      // 1️⃣ Delete expense item
      batch.delete(
        dateRef.collection('items').doc(docId)
      );

      // 2️⃣ Decrement date total
      batch.set(
        dateRef,
        {
          'total': FieldValue.increment(-amount),
          'updatedAt': FieldValue.serverTimestamp()
        
},
        SetOptions(merge: true)
      );

      // 3️⃣ Decrement grand total
      batch.set(
        userRef,
        {
          'grandTotal': FieldValue.increment(-amount)
        
},
        SetOptions(merge: true)
      );

      // 4️⃣ Decrement year total
      batch.set(
        yearRef,
        {
          'grandTotal': FieldValue.increment(-amount)
        
},
        SetOptions(merge: true)
      );

      // 5️⃣ Decrement month stats
      batch.set(
        monthRef,
        {
          type.name: FieldValue.increment(-amount),
          'grandTotal': FieldValue.increment(-amount)
        
},
        SetOptions(merge: true)
      );

      await batch.commit();

      if (kDebugMode) {
        print("⚡ Expense deleted from $dateId: $docId");
      }
    } catch (e) {
      debugPrint("❌ Delete expense failed: $e");
    }
  }

  // 🔹 Expense Stream
  Stream<QuerySnapshot> expenseStream() {
    if (FirebaseAuth.instance.currentUser == null) {
      if (kDebugMode) {
        print("❌ No authenticated user");
      }
      return const Stream.empty();
    }

    if (kDebugMode) {
      print("🔍 Fetching expenses for:");
      print("   User: $uid");
      print("   Date: $currentDateId");
      print("   Path: users/$uid/expenses/$currentDateId/items");
    }

    // 🔧 FIXED: Use currentDateId
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(currentDateId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      if (kDebugMode) {
        print("❌ Stream error: $error");
      }
    });
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
          total: (doc.data()['total'] ?? 0).toDouble()
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error getting expense days: $e");
      }
      return [];
    }
  }


  Future<Map<String, List<ExpenseItem>>> fetchMonthExpenses(
      String monthKey, // yyyy-MM format (e.g., '2025-01')
      ) async {
    final Map<String, List<ExpenseItem>> grouped = {};

    try {
      // Get all expense dates for this month
      final expensesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$monthKey-01')
          .where(FieldPath.documentId, isLessThan: '$monthKey-32') // Covers all days
          .get();

      // Fetch items for each date
      for (final dateDoc in expensesSnapshot.docs) {
        final dateId = dateDoc.id;

        final itemsSnapshot = await dateDoc.reference.collection('items').get();

        if (itemsSnapshot.docs.isEmpty) continue;

        final items = itemsSnapshot.docs.map((itemDoc) {
          return ExpenseItem.fromFirestore(
            itemDoc.id,
            itemDoc.data(),
            dateId,
          );
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

      return YearStats.fromFirestore(
        doc.id,
        doc.data()!
      );
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
          .map((doc) => MonthStats.fromFirestore(
        doc.id,
        doc.data()
      ))
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

      return MonthStats.fromFirestore(
        doc.id,
        doc.data()!
      );
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

      final day = ExpenseDay(
        dateId: dateId,
        total: total,
      );

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)
        ),
        title: const Text(
          'Add Category',
          style: TextStyle(color: Colors.white)
        ),
        content: TextField(
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
              borderSide: BorderSide.none
            )
          )
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[500])
            )
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: const Color(0xFF121212)
            ),
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isEmpty) return;

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('categories')
                    .add({
                  'title': title,
                  'createdAt': FieldValue.serverTimestamp()
                
});

                await fetchCategories();

                if (kDebugMode) {
                  print('✅ Category added: $title');
                }

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              } catch (e) {
                debugPrint('❌ Failed to add category: $e');
              }
            },
            child: const Text('Add')
          )
        ]
      )
    );
  }
}

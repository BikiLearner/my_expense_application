import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../enums/expense_type.dart';
import '../expense_model.dart';
import '../models/income_entry.dart';
import '../models/month_stats.dart';
import '../models/year_stats.dart';

class ExpenseProvider extends ChangeNotifier {
  // 🔹 Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String get currentMonth =>
      DateFormat('yyyy-MM').format(DateTime.now());
  ExpenseType _selectedType = ExpenseType.luxury;
  ExpenseType get selectedType => _selectedType;


  String get currentYear =>
      DateFormat('yyyy').format(DateTime.now());

  // 🔹 Auth UID (SAFE)
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // 🔹 Selected Date
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // 🔹 Firestore

  String _selectedYear = DateTime.now().year.toString();
  String get selectedYear => _selectedYear;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get dateId => DateFormat('yyyy-MM-dd').format(_selectedDate);

  // 🔹 Select Date
  Future<void> selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
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
  }


  void setExpenseType(ExpenseType type) {
    _selectedType = type;
    notifyListeners();
  }

  void setYear(String year) {
    _selectedYear = year;
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
      final dateRef = userRef.collection('expenses').doc(dateId);
      final year = DateFormat('yyyy').format(_selectedDate);
      final month = DateFormat('yyyy-MM').format(_selectedDate);

      // 🔥 Batch write = no reads, faster than transaction
      final batch = _firestore.batch();
      final yearRef = userRef.collection('year_stats').doc(year);
      final monthRef =
      yearRef.collection('months').doc(month);

      // 1️⃣ Update date total (NO READ)
      batch.set(
        dateRef,
        {
          'date': dateId,
          'total': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 2️⃣ Add expense item
      batch.set(
        dateRef.collection('items').doc(),
        {
          'title': title,
          'amount': amount,
          'description': desc,
          'type': _selectedType.name,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // 3️⃣ Update grand total
      batch.set(
        userRef,
        {
          'grandTotal': FieldValue.increment(amount),
        },
        SetOptions(merge: true),
      );

      // ✅ Year grand total
      batch.set(
        yearRef,
        {
          'grandTotal': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

// ✅ Month type totals + month total
      batch.set(
        monthRef,
        {
          'month': month,
          _selectedType.name: FieldValue.increment(amount),
          'grandTotal': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 🚀 Commit once
      await batch.commit();

      clearForm();

      if (kDebugMode) {
        print("⚡ Expense added instantly for $dateId");
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
          .toSet() // 🔥 remove duplicates
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
    required DateTime oldDate,
  }) async {
    final title = titleController.text.trim();
    final newAmount = double.tryParse(amountController.text.trim());
    final desc = descriptionController.text.trim();

    if (title.isEmpty || newAmount == null || newAmount <= 0) return;

    final newType = _selectedType;
    final diff = newAmount - oldAmount;

    final year = DateFormat('yyyy').format(oldDate);
    final month = DateFormat('yyyy-MM').format(oldDate);
    final oldDateId = DateFormat('yyyy-MM-dd').format(oldDate);

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
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2️⃣ Update day total + user grand total
      if (diff != 0) {
        batch.update(dateRef, {
          'total': FieldValue.increment(diff),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        batch.update(userRef, {
          'grandTotal': FieldValue.increment(diff),
        });

        batch.update(yearRef, {
          'grandTotal': FieldValue.increment(diff),
        });
      }

      // 3️⃣ Update month stats
      if (oldType == newType) {
        if (diff != 0) {
          batch.update(monthRef, {
            newType.name: FieldValue.increment(diff),
            'grandTotal': FieldValue.increment(diff),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        batch.update(monthRef, {
          oldType.name: FieldValue.increment(-oldAmount),
          newType.name: FieldValue.increment(newAmount),
          'updatedAt': FieldValue.serverTimestamp(),
        });
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
    // _selectedType = ExpenseType.needed;
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
      batch.set(
        monthRef.collection('items').doc(),
        {
          'amount': amount,
          'source': source,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // 2️⃣ Update monthly total
      batch.set(
        monthRef,
        {
          'month': currentMonth,
          'total': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
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
    required String monthId,   // yyyy-MM
    required String itemId,    // income item doc id
    required double amount,    // item amount
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
      batch.update(
        monthRef,
        {
          'total': FieldValue.increment(-amount),
          'updatedAt': FieldValue.serverTimestamp(),
        },
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

  // 🔥 ADD THIS METHOD TO YOUR ExpenseProvider CLASS

// 🔹 Get all expenses at once (for search/analytics)
// This method fetches everything in one go, reducing Firebase reads
  Future<List<Map<String, dynamic>>> getAllExpensesForSearch() async {
    try {
      final List<Map<String, dynamic>> allExpenses = [];

      // Get all expense dates
      final datesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .get();

      // Fetch items for all dates
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
            'createdAt': data['createdAt'],
          });
        }
      }

      // Sort by date (newest first)
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
  // 🔹 Delete Expense
  Future<void> deleteExpense({
    required String docId,
    required double amount,
    required ExpenseType type,
    required DateTime date,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final deleteDateId = DateFormat('yyyy-MM-dd').format(date);
      final dateRef =
      userRef.collection('expenses').doc(deleteDateId);
      final year = DateFormat('yyyy').format(date);
      final month = DateFormat('yyyy-MM').format(date);

      final yearRef = userRef.collection('year_stats').doc(year);
      final monthRef = yearRef.collection('months').doc(month);
      // ⚡ Batch = no reads, single commit
      final batch = _firestore.batch();

      // 1️⃣ Delete expense item
      batch.delete(
        dateRef.collection('items').doc(docId),
      );

      // 2️⃣ Decrement date total
      batch.update(
        dateRef,
        {
          'total': FieldValue.increment(-amount),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // 3️⃣ Decrement grand total
      batch.update(
        userRef,
        {
          'grandTotal': FieldValue.increment(-amount),
        },
      );
      batch.update(yearRef, {
        'grandTotal': FieldValue.increment(-amount),
      });

      batch.update(monthRef, {
        type.name: FieldValue.increment(-amount),
        'grandTotal': FieldValue.increment(-amount),
      });
      // 🚀 Commit once
      await batch.commit();

      if (kDebugMode) {
        print("⚡ Expense deleted instantly: $docId");
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
      print("   Date: $dateId");
      print("   Path: users/$uid/expenses/$dateId/items");
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(dateId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      if (kDebugMode) {
        print("❌ Stream error: $error");
      }
    });
  }

  // 🔹 All expense dates
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
        doc.data()!,
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
        doc.data(),
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
    // month format: yyyy-MM
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
        doc.data()!,
      );
    } catch (e) {
      if (kDebugMode) {
        print("❌ Failed to fetch month stats ($month): $e");
      }
      return null;
    }
  }


  // 🔹 Total for date
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


  // 🔹 Group by month
  Map<String, List<String>> groupDatesByMonth(List<String> dates) {
    final Map<String, List<String>> grouped = {};

    for (final date in dates) {
      final monthKey = date.substring(0, 7); // yyyy-MM
      grouped.putIfAbsent(monthKey, () => []).add(date);
    }

    return grouped;
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }


  Future<void> migrateExpensesToYearMonthStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(uid);

    try {
      final userDoc = await userRef.get();
      if (userDoc.data()?['migrationCompleted'] == true) {
        if (kDebugMode) {
          print("⏭️ Migration already completed");
        }
        return;
      }

      final expenseDatesSnap =
      await userRef.collection('expenses').get();

      final Map<String, Map<String, Map<String, double>>> stats = {};
      double grandTotal = 0;

      final batch = _firestore.batch(); // 🔥 moved up (needed for updates)

      for (final dateDoc in expenseDatesSnap.docs) {
        final dateRef =
        userRef.collection('expenses').doc(dateDoc.id);

        final itemsSnap = await dateRef.collection('items').get();

        for (final item in itemsSnap.docs) {
          final data = item.data();

          final amount = (data['amount'] as num?)?.toDouble() ?? 0;
          final createdAt =
          (data['createdAt'] as Timestamp?)?.toDate();

          if (createdAt == null || amount <= 0) continue;

          const type = 'luxury'; // 🔥 FORCE LUXURY

          final year = DateFormat('yyyy').format(createdAt);
          final month = DateFormat('yyyy-MM').format(createdAt);

          stats.putIfAbsent(year, () => {});
          stats[year]!.putIfAbsent(month, () => {
            'saving': 0,
            'needed': 0,
            'luxury': 0,
            'grandTotal': 0,
          });

          stats[year]![month]![type] =
              (stats[year]![month]![type] ?? 0) + amount;
          stats[year]![month]!['grandTotal'] =
              (stats[year]![month]!['grandTotal'] ?? 0) + amount;

          grandTotal += amount;

          // 🔥 Normalize old item
          batch.update(item.reference, {
            'type': 'luxury',
          });
        }
      }

      // 🔹 Write year & month stats
      stats.forEach((year, months) {
        final yearRef = userRef.collection('year_stats').doc(year);

        double yearTotal = 0;
        months.forEach((_, values) {
          yearTotal += values['grandTotal'] ?? 0;
        });

        batch.set(
          yearRef,
          {
            'grandTotal': yearTotal,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        months.forEach((month, values) {
          batch.set(
            yearRef.collection('months').doc(month),
            {
              'month': month,
              ...values,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        });
      });

      // 🔹 Mark migration done
      batch.set(
        userRef,
        {
          'grandTotal': grandTotal,
          'migrationCompleted': true,
          'migrationAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      AlertDialog(
        content: Dialog(

        ),
      );

      if (kDebugMode) {
        print("🎉 Migration completed — ALL expenses set to LUXURY");
      }
    } catch (e) {
      debugPrint("❌ Migration failed: $e");
    }
  }


  void showMigrationCompletedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent.withOpacity(0.15),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Migration Completed",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "All previous expenses have been successfully migrated and marked as Luxury.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64FFDA),
                  foregroundColor: const Color(0xFF121212),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Done",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> migrateOldExpenses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(uid);

    try {
      final expenseDatesSnap =
      await userRef.collection('expenses').get();

      double grandTotal = 0;

      for (final dateDoc in expenseDatesSnap.docs) {
        final dateId = dateDoc.id;
        final dateRef = userRef.collection('expenses').doc(dateId);

        // 🔹 Skip if already migrated
        if (dateDoc.data().containsKey('total')) {
          grandTotal += (dateDoc['total'] ?? 0).toDouble();
          if (kDebugMode) {
            print("⏭️ Skipping $dateId (already migrated)");
          }
          continue;
        }

        // 🔹 Read items and calculate total
        final itemsSnap =
        await dateRef.collection('items').get();

        double dayTotal = 0;
        for (final item in itemsSnap.docs) {
          dayTotal += (item['amount'] as num).toDouble();
        }

        // 🔹 Write total to date document
        await dateRef.set({
          'date': dateId,
          'total': dayTotal,
          'migrated': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        grandTotal += dayTotal;

        if (kDebugMode) {
          print("✅ Migrated $dateId → ₹$dayTotal");
        }
      }

      // 🔹 Save grand total
      await userRef.set({
        'grandTotal': grandTotal,
        'migrationCompleted': true,
        'migrationAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print("🎉 Migration completed. Grand Total = ₹$grandTotal");
      }
    } catch (e) {
      debugPrint("❌ Migration failed: $e");
    }
  }


  Future<void> showAddCategoryDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Add Category',
          style: TextStyle(color: Colors.white),
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
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[500]),
            ),
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
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('categories')
                    .add({
                  'title': title,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (kDebugMode) {
                  print('✅ Category added: $title');
                }

                Navigator.pop(ctx);
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

}
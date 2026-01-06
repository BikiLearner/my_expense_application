import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../expense_model.dart';
import '../models/income_entry.dart';

class ExpenseProvider extends ChangeNotifier {
  // 🔹 Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String get currentMonth =>
      DateFormat('yyyy-MM').format(DateTime.now());

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

      // 🔥 Batch write = no reads, faster than transaction
      final batch = _firestore.batch();

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

      // 🚀 Commit once
      await batch.commit();

      titleController.clear();
      amountController.clear();
      descriptionController.clear();

      if (kDebugMode) {
        print("⚡ Expense added instantly for $dateId");
      }
    } catch (e) {
      debugPrint("❌ Add expense failed: $e");
    }
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
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final dateRef = userRef.collection('expenses').doc(dateId);

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

}
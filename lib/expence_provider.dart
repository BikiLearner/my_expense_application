import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'expense_model.dart';

class ExpenseProvider extends ChangeNotifier {
  // 🔹 Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // 🔹 Auth UID (SAFE)
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // 🔹 Selected Date
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // 🔹 Firestore
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
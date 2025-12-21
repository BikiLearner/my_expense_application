import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
    if (FirebaseAuth.instance.currentUser == null) return;

    final title = titleController.text.trim();
    final amount = double.tryParse(amountController.text.trim());
    final desc = descriptionController.text.trim();

    if (title.isEmpty || amount == null || amount <= 0) return;

    try {
      // ✅ Create reference to the date document
      final dateDocRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(dateId);

      // ✅ Ensure the date document exists first
      await dateDocRef.set({
        'date': dateId,
      }, SetOptions(merge: true));

      // ✅ Then add the expense item to subcollection
      await dateDocRef.collection('items').add({
        'title': title,
        'amount': amount,
        'description': desc,
        'createdAt': FieldValue.serverTimestamp(),
      });

      titleController.clear();
      amountController.clear();
      descriptionController.clear();

      if (kDebugMode) {
        print("✅ Expense added successfully for date: $dateId");
      }
    } catch (e) {
      debugPrint("❌ Add expense failed: $e");
    }
  }

  // 🔹 Delete Expense
  Future<void> deleteExpense(String docId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(dateId)
          .collection('items')
          .doc(docId)
          .delete();

      if (kDebugMode) {
        print("✅ Expense deleted: $docId");
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
  Future<List<String>> getAllExpenseDates() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .get();

      if (kDebugMode) {
        print("📅 Found ${snapshot.docs.length} expense dates");
      }

      return snapshot.docs.map((d) => d.id).toList();
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error getting expense dates: $e");
      }
      return [];
    }
  }

  // 🔹 Total for date
  Future<double> getTotalForDate(String dateId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(dateId)
          .collection('items')
          .get();

      double total = 0;
      for (var d in snapshot.docs) {
        total += (d['amount'] as num).toDouble();
      }

      if (kDebugMode) {
        print("💰 Total for $dateId: $total");
      }

      return total;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error getting total: $e");
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
}
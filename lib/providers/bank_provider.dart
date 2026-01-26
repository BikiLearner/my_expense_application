import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/bank_model.dart';
import '../models/bank_month_entry_model.dart';
import '../models/bank_month_model.dart';

class BankProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  List<BankModel> _banks = [];
  List<BankModel> get banks => _banks;

  StreamSubscription? _sub;
  bool isLoading = false;

  void listenBanks() {
    isLoading = true;
    notifyListeners();

    _sub?.cancel();
    _sub = _firestore
        .collection('users')
        .doc(uid)
        .collection('bank')
        .snapshots()
        .listen((snapshot) {
      _banks = snapshot.docs
          .map((e) => BankModel.fromFirestore(e.id, e.data()))
          .toList();

      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addBank({
    required String bankName,
    required double amount,
  }) async {
    final now = DateTime.now();
    final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final bankRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('bank')
        .doc();

    final monthRef = bankRef
        .collection('monthAmount')
        .doc(monthId);

    final entryRef = monthRef
        .collection('entries')
        .doc();

    await _firestore.runTransaction((tx) async {
      // 1️⃣ Create bank document
      tx.set(bankRef, {
        'bankName': bankName,
        'totalAmountWhenAdded': amount,
        'currentAmount': amount,
        'addedDate': Timestamp.now(),
      });

      // 2️⃣ Create initial month summary
      tx.set(monthRef, {
        'totalAdded': amount,
        'currentAmount': amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3️⃣ Create initial entry (history)
      tx.set(entryRef, {
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
  double get totalBankBalance {
    return _banks.fold<double>(
      0.0,
          (sum, bank) => sum + bank.currentAmount,
    );
  }

  Future<void> updateBank({
    required String bankId,
    required String bankName,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('bank')
        .doc(bankId)
        .update({
      'bankName': bankName,
    });
  }

// Add this method to BankProvider class
// Add this to your BankProvider class
  Stream<List<BankMonthEntry>> streamMonthEntries(String bankId, String monthId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('bank')
        .doc(bankId)
        .collection('monthAmount')
        .doc(monthId)
        .collection('entries')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((e) => BankMonthEntry.fromFirestore(e.id, e.data()))
          .toList();
    });
  }
  // 🔹 Stream monthAmount for a bank
  Stream<List<BankMonthModel>> streamBankMonths(String bankId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('bank')
        .doc(bankId)
        .collection('monthAmount')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((e) => BankMonthModel.fromFirestore(e.id, e.data()))
          .toList();
    });
  }


// 🔹 Add / update monthAmount
// 🔹 Add amount to current month (MULTIPLE TIMES SAFE)
  Future<void> addMonthAmount({
    required String bankId,
    required double amount,
  }) async {
    final now = DateTime.now();
    final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final bankRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('bank')
        .doc(bankId);

    final monthRef = bankRef
        .collection('monthAmount')
        .doc(monthId);

    final entryRef = monthRef
        .collection('entries')
        .doc();

    await _firestore.runTransaction((tx) async {
      final bankSnap = await tx.get(bankRef);
      final monthSnap = await tx.get(monthRef);

      final currentBankAmount =
      (bankSnap.data()?['currentAmount'] ?? 0).toDouble();

      final monthTotal =
      (monthSnap.data()?['totalAdded'] ?? 0).toDouble();

      final newBankAmount = currentBankAmount + amount;
      final newMonthTotal = monthTotal + amount;

      // 1️⃣ Add entry (history)
      tx.set(entryRef, {
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2️⃣ Update / create month summary
      tx.set(monthRef, {
        'totalAdded': newMonthTotal,
        'currentAmount': newBankAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3️⃣ Update bank totals
      tx.update(bankRef, {
        'currentAmount': newBankAmount,
        'totalAmountWhenAdded': FieldValue.increment(amount),
      });
    });
  }

  String getTransactionBankName(String id){
    return _banks.firstWhere((element) => element.id == id).bankName;
  }


  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

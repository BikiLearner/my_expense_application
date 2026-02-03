import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/credit_model.dart';
import 'bank_provider.dart';

class BankCreditProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  StreamSubscription? _sub;

  /// 🔥 STREAMED LISTS
  List<BankCredit> _borrow = [];
  List<BankCredit> _lent = [];
  List<BankCredit> _completed = [];

  List<BankCredit> get borrow => _borrow;
  List<BankCredit> get lent => _lent;
  List<BankCredit> get completed => _completed;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  BankCreditProvider() {
    _listenCredits();
  }

  // ───────────────── STREAM ─────────────────

  void _listenCredits() {
    _sub?.cancel();

    _sub = _firestore
        .collection('users')
        .doc(uid)
        .collection('credits')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _borrow = [];
      _lent = [];
      _completed = [];

      for (final doc in snapshot.docs) {
        final credit = BankCredit.fromFirestore(doc.id, doc.data());

        if (credit.status == CreditStatus.completed) {
          _completed.add(credit);
        } else if (credit.type == CreditType.borrow) {
          _borrow.add(credit);
        } else {
          _lent.add(credit);
        }
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  // ───────────────── CREATE ─────────────────

  Future<void> addBorrow({
    required String title,
    required double amount,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('credits')
        .add({
      'title': title,
      'amount': amount,
      'type': 'borrow',
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addLent({
    required String title,
    required double amount,
    required String bankId,
    required BankProvider bankProvider,
  }) async {
    // 🔹 1️⃣ Deduct bank immediately
    await bankProvider.deductForLent(
      bankId: bankId,
      amount: amount,
      description: 'Lent: $title',
    );

    // 🔹 2️⃣ Save credit
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('credits')
        .add({
      'title': title,
      'amount': amount,
      'type': 'lent',
      'status': 'active',
      'bankId': bankId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ───────────────── COMPLETE ─────────────────

  Future<void> completeBorrow({
    required BankCredit credit,
    required BuildContext context,
    required Function payBorrowAsExpense,
  }) async {
    // Expense + bank handled by ExpenseProvider
    await payBorrowAsExpense();

    await _markCompleted(credit.id);
  }

  Future<void> receiveLent({
    required BankCredit credit,
    required BankProvider bankProvider,
  }) async {
    // 🔹 Add money back to bank
    await bankProvider.addMonthAmount(
      bankId: credit.bankId!,
      amount: credit.amount,
      description: 'Lent returned: ${credit.title}',
    );

    await _markCompleted(credit.id);
  }

  Future<void> _markCompleted(String creditId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('credits')
        .doc(creditId)
        .update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // ───────────────── CLEANUP ─────────────────

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

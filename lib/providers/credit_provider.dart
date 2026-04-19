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

  final List<BankCredit> _borrow = [];
  final List<BankCredit> _lent = [];
  final List<BankCredit> _completed = [];

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
      _borrow.clear();
      _lent.clear();
      _completed.clear();

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
  }) {
    return _createCredit(
      title: title,
      amount: amount,
      type: CreditType.borrow,
    );
  }

  Future<void> addLent({
    required String title,
    required double amount,
    required String bankId,
    required BankProvider bankProvider,
  }) async {
    await _firestore.runTransaction((tx) async {
      // 1️⃣ Deduct bank
      await bankProvider.deductForLent(
        bankId: bankId,
        amount: amount,
        description: 'Lent: $title',
      );

      // 2️⃣ Create credit
      await _createCredit(
        title: title,
        amount: amount,
        type: CreditType.lent,
        bankId: bankId,
        transaction: tx,
      );
    });
  }

  Future<void> _createCredit({
    required String title,
    required double amount,
    required CreditType type,
    String? bankId,
    Transaction? transaction,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('credits')
        .doc();

    final data = {
      'title': title,
      'amount': amount,
      'type': type.name,
      'status': CreditStatus.active.name,
      'bankId': bankId,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (transaction != null) {
      transaction.set(ref, data);
    } else {
      await ref.set(data);
    }
  }

  // ───────────────── COMPLETE ─────────────────

  Future<void> completeBorrow({
    required BankCredit credit,
    required Future<void> Function() payAsExpense,
  }) async {
    await payAsExpense();
    await _markCompleted(credit.id);
  }

  Future<void> receiveLent({
    required BankCredit credit,
    required BankProvider bankProvider,
  }) async {
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
      'status': CreditStatus.completed.name,
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


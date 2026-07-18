import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expence_app/core/constants/collection_name_constant.dart';
import 'package:expence_app/core/services/session_maganger.dart';
import 'package:flutter/foundation.dart';

import '../model/bank_model.dart';
import '../model/bank_month_entry_model.dart';
import '../model/bank_month_model.dart';

class BankDatasource {
  BankDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference userReference = SessionManager.instance.userRef;

  // all reference generator methods
  CollectionReference<Map<String, dynamic>> _bankCollectionRef() {
    return userReference.collection(CollectionName.bank);
  }

  DocumentReference<Map<String, dynamic>> _bankRef({String? bankId}) =>
      userReference.collection(CollectionName.bank).doc(bankId);

  CollectionReference<Map<String, dynamic>> _monthAmount({
    required DocumentReference bankRef,
  }) {
    return bankRef.collection(CollectionName.monthAmount);
  }

  DocumentReference<Map<String, dynamic>> _monthAmountdocRef({
    required String monthId,
    required DocumentReference bankRef,
  }) {
    return _monthAmount(bankRef: bankRef).doc(monthId);
  }

  CollectionReference<Map<String, dynamic>> _entries({
    required DocumentReference monthRef,
  }) {
    return monthRef.collection(CollectionName.entries);
  }

  DocumentReference<Map<String, dynamic>> _entryDocRef({
    String? entryId,
    required DocumentReference monthRef,
  }) {
    return _entries(monthRef: monthRef).doc(entryId);
  }

  // Query<Map<String, dynamic>> _allEntriesQuery({
  //   required DocumentReference monthRef,
  // }) {
  //   return _entries(monthRef: monthRef).orderBy('createdAt', descending: true);
  // }

  String getMonthId([DateTime? date]) {
    final d = date ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  /// 🔄 Transfer money between banks
  Future<void> transferBetweenBanks({
    required String fromBankId,
    required String toBankId,
    required double amount,
    required String description,
  }) async {
    final monthId = getMonthId();

    final fromBankRef = _bankRef(bankId: fromBankId);
    final toBankRef = _bankRef(bankId: toBankId);

    final fromMonthRef = _monthAmountdocRef(
      monthId: monthId,
      bankRef: fromBankRef,
    );
    final toMonthRef = _monthAmountdocRef(monthId: monthId, bankRef: toBankRef);

    // 🔹 Create transfer entry references
    final fromEntryRef = _entryDocRef(monthRef: fromMonthRef);
    final toEntryRef = _entryDocRef(monthRef: toMonthRef);

    try {
      await _firestore.runTransaction((tx) async {
        await _validateTransfer(
          tx: tx,
          fromBankRef: fromBankRef,
          toBankRef: toBankRef,
          fromMonthRef: fromMonthRef,
          toMonthRef: toMonthRef,
          transferAmount: amount,
        );

        _updateBankMonthAmount(tx: tx, monthRef: fromMonthRef, delta: -amount);

        _createBankEntry(
          tx: tx,
          entryRef: fromEntryRef,
          amount: -amount,
          description: 'Transfer to: $description',
          type: 'transfer_out',
          targetBankId: toBankId,
        );

        // 4️⃣ Add to destination bank
        _updateBankMonthAmount(
          tx: tx,
          monthRef: toMonthRef,
          delta: amount,
          isIncoming: true, // Also increments totalAdded
        );

        _createBankEntry(
          tx: tx,
          entryRef: toEntryRef,
          amount: amount,
          description: 'Transfer from: $description',
          type: 'transfer_in',
          sourceBankId: fromBankId,
        );
      });

      if (kDebugMode) {
        print('✅ Bank transfer successful: ₹$amount');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Bank transfer failed: $e');
      }
      rethrow; // Let the UI handle the error
    }
  }

  Future<List<BankModel>> fetchBanks() async {
    final snapshot = await _bankCollectionRef().get();

    return snapshot.docs.map((doc) {
      return BankModel.fromFirestore(doc.id, doc.data());
    }).toList();
  }

  Future<List<BankMonthModel>> fetchBankMonthAmount(String bankId) async {
    final snapshot = await _bankRef(
      bankId: bankId,
    ).collection(CollectionName.monthAmount).get();

    return snapshot.docs
        .map((doc) => BankMonthModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<List<BankMonthEntry>> fetchBankMonthEntries({
    required String bankId,
    required String monthId,
  }) async {
    final snapshot = await _monthAmountdocRef(
      bankRef: _bankRef(bankId: bankId),
      monthId: monthId,
    ).collection(CollectionName.entries).get();

    return snapshot.docs
        .map((doc) => BankMonthEntry.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<void> addBank({
    required String bankName,
    required double amount,
  }) async {
    try {
      final monthId = getMonthId();

      final bankRef = _bankRef();

      final monthRef = _monthAmountdocRef(monthId: monthId, bankRef: bankRef);

      final entryRef = _entryDocRef(monthRef: monthRef);

      await _firestore.runTransaction((tx) async {
        // 1️⃣ Create bank document
        tx.set(bankRef, {'bankName': bankName, 'addedDate': Timestamp.now()});

        // 2️⃣ Create initial month summary

        tx.set(monthRef, {
          'totalAdded': amount,
          'currentAmount': amount,
          'surplusPreviousMonth': 0,
          'incomeThisMonth': amount,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 3️⃣ Create initial entry (history)
        tx.set(entryRef, {
          'amount': amount,
          'description': 'Initial amount',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      // ❌ Catch the error here in the data layer, then throw it
      // so the Provider's try/catch block can handle it and show the SnackBar.
      if (kDebugMode) {
        print('DataSource Error (addBank): $e');
      }

      // You can either throw a clean custom exception:
      throw Exception('Failed to add new bank. Please try again.');
    }
  }

  Future<void> addMonthAmount({
    required String bankId,
    required double amount,
    String? description = "Not Provided",
  }) async {
    final now = DateTime.now();
    final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final bankRef = _bankRef(bankId: bankId);

    final monthRef = _monthAmountdocRef(monthId: monthId, bankRef: bankRef);

    final entryRef = _entryDocRef(monthRef: monthRef);

    await _firestore.runTransaction((tx) async {
      // debugPrint('🏦 addMonthAmount → monthRef: ${monthRef.path}');
      // debugPrint('🏦 addMonthAmount → entryRef: ${entryRef.path}');
      // debugPrint('🏦 addMonthAmount → uid: ${userReference.id}');
      // final bankSnap = await tx.get(bankRef);
      final monthSnap = await tx.get(monthRef);

      final monthTotal = (monthSnap.data()?['totalAdded'] ?? 0).toDouble();
      final monthIncomePrevious = (monthSnap.data()?['incomeThisMonth'] ?? 0)
          .toDouble();
      final currentBankAmount = (monthSnap.data()?['currentAmount'] ?? 0)
          .toDouble();

      final newBankAmount = currentBankAmount + amount;
      final newMonthTotal = monthTotal + amount;
      final newIncome = monthIncomePrevious + amount;

      // 1️⃣ Add entry (history)
      _createBankEntry(
        tx: tx,
        entryRef: entryRef,
        amount: amount,
        description: description ?? 'Not Provided',
      );

      // 2️⃣ Update / create month summary
      tx.set(monthRef, {
        'totalAdded': newMonthTotal,
        'currentAmount': newBankAmount,
        'incomeThisMonth': newIncome,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> editBankMonth({
    required String bankId,
    required String monthId, // yyyy-MM
    required double totalAdded,
    required double incomeThisMonth,
    required double surplusPreviousMonth,
    required double currentAmount,
  }) async {
    try {
      final bankRef = _bankRef(bankId: bankId);
      final monthRef = _monthAmountdocRef(monthId: monthId, bankRef: bankRef);

      await _firestore.runTransaction((tx) async {
        final monthSnap = await tx.get(monthRef);

        if (!monthSnap.exists) {
          throw Exception('❌ Month does not exist, cannot edit');
        }

        tx.update(monthRef, {
          'totalAdded': totalAdded,
          'incomeThisMonth': incomeThisMonth,
          'surplusPreviousMonth': surplusPreviousMonth,
          'currentAmount': currentAmount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to edit bank month: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  // ===========================================================================
  // DATASOURCE METHODS
  // ===========================================================================

  /// 1️⃣ Checks if the bank and current month exist.
  /// Returns the surplus if the month already exists.
  Future<({bool bankExists, bool monthExists, double surplus})>
  checkBankAndMonthStatus({required String bankId}) async {
    final bankRef = _bankRef(bankId: bankId);
    final monthId = getMonthId();
    final monthRef = _monthAmountdocRef(monthId: monthId, bankRef: bankRef);

    final bankSnap = await bankRef.get();
    if (!bankSnap.exists) {
      return (bankExists: false, monthExists: false, surplus: 0.0);
    }

    final monthSnap = await monthRef.get();
    if (monthSnap.exists) {
      // 🔥 FIX: Explicitly declare 'final double' and safely cast 'as num?'
      // before calling .toDouble() to guarantee strict typing.
      final double surplus =
          (monthSnap.data()?['surplusPreviousMonth'] as num?)?.toDouble() ??
          0.0;

      return (bankExists: true, monthExists: true, surplus: surplus);
    }

    return (bankExists: true, monthExists: false, surplus: 0.0);
  }

  /// 2️⃣ Calculates the previous month and fetches its closing balance.
  Future<double> getPreviousMonthClosing({required String bankId}) async {
    final bankRef = _bankRef(bankId: bankId);
    final snapshot = await _monthAmount(bankRef: bankRef).get();
    final monthId = getMonthId();

    if (snapshot.docs.isEmpty) return 0.0;

    final months =
        snapshot.docs
            .map((doc) => doc.id)
            .where((id) => id.compareTo(monthId) < 0)
            .toList()
          ..sort();

    if (months.isEmpty) return 0.0;

    final latestPreviousMonthId = months.last;

    final previousDoc = snapshot.docs.firstWhere(
      (doc) => doc.id == latestPreviousMonthId,
    );

    return (previousDoc.data()['currentAmount'] ?? 0).toDouble();
  }

  Future<double?> getBankMonthBalance({required String bankId}) async {
    final bankRef = _bankRef(bankId: bankId);
    final monthId = getMonthId();
    final doc = _monthAmountdocRef(monthId: monthId, bankRef: bankRef);

    final snapshot = await doc.get();

    if (!snapshot.exists) return null;

    return (snapshot.data()?['currentAmount'] ?? 0).toDouble();
  }

  Stream<List<BankMonthModel>> streamBankMonthAmount(String bankId) {
    final bankRef = _bankRef(bankId: bankId);
    return _monthAmount(bankRef: bankRef).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => BankMonthModel.fromFirestore(doc.id, doc.data()))
          .toList(),
    );
  }

  /// 3️⃣ Runs the transaction to save the newly initialized month.
  Future<void> initializeBankMonth({
    required String bankId,

    required double surplusValue,
    required double totalAdded,
    required double currentAmount,
  }) async {
    final bankRef = _bankRef(bankId: bankId);
    final monthId = getMonthId();
    final monthRef = _monthAmountdocRef(monthId: monthId, bankRef: bankRef);

    await _firestore.runTransaction((tx) async {
      tx.set(monthRef, {
        'surplusPreviousMonth': surplusValue,
        'totalAdded': totalAdded,
        'incomeThisMonth': 0,
        'currentAmount': currentAmount,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _validateTransfer({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> fromBankRef,
    required DocumentReference<Map<String, dynamic>> toBankRef,
    required DocumentReference<Map<String, dynamic>> fromMonthRef,
    required DocumentReference<Map<String, dynamic>> toMonthRef,
    required double transferAmount,
  }) async {
    final fromBankSnap = await tx.get(fromBankRef);
    final toBankSnap = await tx.get(toBankRef);
    final fromMonthSnap = await tx.get(fromMonthRef);
    final toMonthSnap = await tx.get(toMonthRef);

    if (!fromBankSnap.exists || !toBankSnap.exists) {
      throw Exception('One or both banks not found');
    }
    if (!fromMonthSnap.exists) {
      throw Exception('Source bank month not initialized');
    }
    if (!toMonthSnap.exists) {
      throw Exception('Destination bank month not initialized');
    }

    final fromCurrentAmount = (fromMonthSnap.data()?['currentAmount'] ?? 0)
        .toDouble();
    if (fromCurrentAmount < transferAmount) {
      throw Exception('Insufficient balance in source bank');
    }
  }

  /// Updates the balance of a bank month.
  /// If `isIncoming` is true, it also increases the `totalAdded` field.
  void _updateBankMonthAmount({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> monthRef,
    required double delta,
    bool isIncoming = false,
  }) {
    final updates = <String, dynamic>{
      'currentAmount': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isIncoming) {
      updates['totalAdded'] = FieldValue.increment(delta);
    }

    tx.update(monthRef, updates);
  }

  /// Creates a standard entry document inside a bank month's 'entries' collection.
  void _createBankEntry({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> entryRef,
    required double amount,
    required String description,
    String? type,
    String? targetBankId,
    String? sourceBankId,
  }) {
    tx.set(entryRef, {
      'amount': amount,
      'description': description,
      if (type != null) 'type': type,
      if (targetBankId != null) 'targetBankId': targetBankId,
      if (sourceBankId != null) 'sourceBankId': sourceBankId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

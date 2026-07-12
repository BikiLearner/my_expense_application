// expense_firestore_datasource.dart
//
// Extracted from ExpenseProvider as part of the Clean Architecture refactor.
// This is the ONLY class in the `expense` feature allowed to talk to
// Firestore directly (FirebaseFirestore, CollectionReference,
// DocumentReference, WriteBatch, Transaction, FieldValue, snapshots(),
// get(), set(), update(), delete(), runTransaction()).
//
// NOTE ON BEHAVIOR PARITY:
// All field names, collection names, document ids, timestamps and
// FieldValue.increment() calls are copied exactly from the original
// ExpenseProvider. The only intentional change (mandated by the refactor
// spec) is that addExpense(), editExpense() and deleteExpense() now perform
// their bank + expense + stats writes inside a SINGLE runTransaction()
// instead of a batch followed by a separate transaction, so that everything
// commits atomically or nothing does.
//
// Income methods (addIncome / deleteIncome / getYearIncomeFromFirestore)
// were intentionally removed — Income is a separate feature and is not
// usable here.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/models/month_stats.dart';
import '../../../../shared/models/year_stats.dart';
import '../model/expense_items.dart';
import '../model/expense_model.dart';

class ExpenseFirestoreDatasource {
  ExpenseFirestoreDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ===========================================================================
  // PUBLIC API
  // ===========================================================================

  /// Adds an expense item, updates the daily total, the month stats, the
  /// year stats and the user's grand total. If the expense is paid from a
  /// bank (i.e. not cash), the bank month balance is validated and deducted
  /// in the SAME transaction, so either everything succeeds or nothing does.
  Future<void> addExpense({
    required String uid,
    required String dateId,
    required String title,
    required double amount,
    required String description,
    required String expenseTypeName,
    required String? transactionTypeId,
    required DateTime itemCreatedAt,
  }) async {
    final refs = _buildExpenseReferences(uid: uid, dateId: dateId);
    final isCash = _isCash(transactionTypeId);

    final bankRef = isCash
        ? null
        : _bankRef(uid: uid, bankId: transactionTypeId!);
    final bankMonthId = dateId.substring(0, 7);
    final bankMonthRef = isCash
        ? null
        : _bankMonthRef(
      uid: uid,
      bankId: transactionTypeId!,
      monthId: bankMonthId,
    );

    await _firestore.runTransaction((tx) async {
      // 1️⃣ Validate bank (reads must happen before any writes)
      await _validateBank(
        tx: tx,
        bankRef: bankRef,
        bankMonthRef: bankMonthRef,
        amount: amount,
        isCash: isCash,
      );

      // 2️⃣ Deduct bank balance
      _updateBankBalance(
        tx: tx,
        bankMonthRef: bankMonthRef,
        isCash: isCash,
        delta: -amount,
      );

      // 3️⃣ Create the expense item document
      _createExpenseDocument(
        tx: tx,
        dateRef: refs.dateRef,
        title: title,
        amount: amount,
        description: description,
        expenseTypeName: expenseTypeName,
        transactionTypeId: transactionTypeId,
        createdAt: itemCreatedAt,
      );

      // 4️⃣ Update the daily total
      _updateDailyTotal(tx: tx, dateRef: refs.dateRef, delta: amount, dateId: dateId);

      // 5️⃣ Update month type totals + month grand total
      _updateMonthStatsForAdd(
        tx: tx,
        monthRef: refs.monthRef,
        monthId: refs.month,
        expenseTypeName: expenseTypeName,
        amount: amount,
      );

      // 6️⃣ Update year grand total
      _updateYearGrandTotal(tx: tx, yearRef: refs.yearRef, delta: amount);

      // 7️⃣ Update user grand total
      _updateGrandTotal(tx: tx, userRef: refs.userRef, delta: amount);
    });
  }

  /// Edits an existing expense item. Recomputes daily/month/year/grand
  /// totals from the amount diff, and reconciles bank balances:
  /// - if the bank did not change: adjusts the same bank month by the diff
  /// - if the bank changed: restores the old bank month and deducts from
  ///   the new bank month
  /// Everything happens inside a single transaction.
  Future<void> editExpense({
    required String uid,
    required String docId,
    required double oldAmount,
    required String oldTypeName,
    required DateTime oldDate,
    required String? oldTransactionTypeId,
    required String title,
    required double newAmount,
    required String description,
    required String newTypeName,
    required String? newTransactionTypeId,
  }) async {
    final dateId = _formatDate(oldDate);
    final year = dateId.substring(0, 4);
    final monthId = dateId.substring(0, 7);
    final diff = newAmount - oldAmount;

    final userRef = _userRef(uid);
    final dateRef = userRef.collection('expenses').doc(dateId);
    final itemRef = dateRef.collection('items').doc(docId);
    final yearRef = userRef.collection('year_stats').doc(year);
    final monthRef = yearRef.collection('months').doc(monthId);

    final sameBank =
        oldTransactionTypeId == newTransactionTypeId &&
            oldTransactionTypeId != null &&
            oldTransactionTypeId != 'cash';

    await _firestore.runTransaction((tx) async {
      // ---------------- READS (must all happen before writes) ----------------
      DocumentReference<Map<String, dynamic>>? sameBankMonthRef;
      DocumentSnapshot<Map<String, dynamic>>? sameBankMonthSnap;
      DocumentReference<Map<String, dynamic>>? oldBankMonthRef;
      DocumentSnapshot<Map<String, dynamic>>? oldBankMonthSnap;
      DocumentReference<Map<String, dynamic>>? newBankMonthRef;
      DocumentSnapshot<Map<String, dynamic>>? newBankMonthSnap;

      if (sameBank) {
        if (diff != 0) {
          sameBankMonthRef = _bankMonthRef(
            uid: uid,
            bankId: oldTransactionTypeId!,
            monthId: monthId,
          );
          sameBankMonthSnap = await tx.get(sameBankMonthRef);
        }
      } else {
        if (oldTransactionTypeId != null && oldTransactionTypeId != 'cash') {
          oldBankMonthRef = _bankMonthRef(
            uid: uid,
            bankId: oldTransactionTypeId,
            monthId: monthId,
          );
          oldBankMonthSnap = await tx.get(oldBankMonthRef);
        }
        if (newTransactionTypeId != null && newTransactionTypeId != 'cash') {
          newBankMonthRef = _bankMonthRef(
            uid: uid,
            bankId: newTransactionTypeId,
            monthId: monthId,
          );
          newBankMonthSnap = await tx.get(newBankMonthRef);
        }
      }

      // ---------------- VALIDATE ----------------
      _validateEditBankBalances(
        sameBank: sameBank,
        diff: diff,
        newAmount: newAmount,
        sameBankMonthSnap: sameBankMonthSnap,
        newBankMonthRef: newBankMonthRef,
        newBankMonthSnap: newBankMonthSnap,
      );

      // ---------------- WRITES ----------------
      _updateExpenseItem(
        tx: tx,
        itemRef: itemRef,
        title: title,
        amount: newAmount,
        description: description,
        typeName: newTypeName,
        transactionTypeId: newTransactionTypeId,
      );

      if (diff != 0) {
        _updateDailyTotal(tx: tx, dateRef: dateRef, delta: diff);
        _updateGrandTotal(tx: tx, userRef: userRef, delta: diff);
        _updateYearGrandTotal(tx: tx, yearRef: yearRef, delta: diff);
      }

      if (oldTypeName == newTypeName) {
        if (diff != 0) {
          _updateMonthStatsForEditSameType(
            tx: tx,
            monthRef: monthRef,
            typeName: newTypeName,
            diff: diff,
          );
        }
      } else {
        _updateMonthStatsForEditTypeChanged(
          tx: tx,
          monthRef: monthRef,
          oldType: oldTypeName,
          oldAmount: oldAmount,
          newType: newTypeName,
          newAmount: newAmount,
        );
      }

      if (sameBank) {
        if (diff != 0 &&
            sameBankMonthRef != null &&
            sameBankMonthSnap != null &&
            sameBankMonthSnap.exists) {
          _updateBankMonthAmount(
            tx: tx,
            bankMonthRef: sameBankMonthRef,
            delta: -diff,
          );
        }
      } else {
        if (oldBankMonthRef != null &&
            oldBankMonthSnap != null &&
            oldBankMonthSnap.exists) {
          _updateBankMonthAmount(
            tx: tx,
            bankMonthRef: oldBankMonthRef,
            delta: oldAmount,
          );
        }
        if (newBankMonthRef != null) {
          _updateBankMonthAmount(
            tx: tx,
            bankMonthRef: newBankMonthRef,
            delta: -newAmount,
          );
        }
      }
    });
  }

  /// Deletes an expense item, decrements daily/month/year/grand totals and
  /// restores the bank month balance (if the expense was paid from a bank),
  /// all inside a single transaction.
  Future<void> deleteExpense({
    required String uid,
    required String docId,
    required double amount,
    required String typeName,
    required String dateId,
    required String? bankId,
  }) async {
    final userRef = _userRef(uid);
    final dateRef = userRef.collection('expenses').doc(dateId);
    final itemRef = dateRef.collection('items').doc(docId);
    final year = dateId.substring(0, 4);
    final month = dateId.substring(0, 7);
    final yearRef = userRef.collection('year_stats').doc(year);
    final monthRef = yearRef.collection('months').doc(month);

    final restoresBank = bankId != null && bankId != 'cash';
    final bankRef = restoresBank ? _bankRef(uid: uid, bankId: bankId!) : null;
    final bankMonthRef = restoresBank
        ? _bankMonthRef(uid: uid, bankId: bankId!, monthId: month)
        : null;

    await _firestore.runTransaction((tx) async {
      // ---------------- READS ----------------
      DocumentSnapshot<Map<String, dynamic>>? bankSnap;
      DocumentSnapshot<Map<String, dynamic>>? bankMonthSnap;
      if (restoresBank) {
        bankSnap = await tx.get(bankRef!);
        bankMonthSnap = await tx.get(bankMonthRef!);
      }

      // ---------------- WRITES ----------------
      _deleteExpenseDocument(tx: tx, itemRef: itemRef);
      _updateDailyTotal(tx: tx, dateRef: dateRef, delta: -amount);
      _updateGrandTotal(tx: tx, userRef: userRef, delta: -amount);
      _updateYearGrandTotal(
        tx: tx,
        yearRef: yearRef,
        delta: -amount,
        includeUpdatedAt: false,
      );
      _updateMonthStatsForDelete(
        tx: tx,
        monthRef: monthRef,
        typeName: typeName,
        amount: amount,
      );

      if (restoresBank &&
          bankSnap != null &&
          bankSnap.exists &&
          bankMonthSnap != null &&
          bankMonthSnap.exists) {
        _updateBankMonthAmount(
          tx: tx,
          bankMonthRef: bankMonthRef!,
          delta: amount,
        );
      }
    });
  }

  /// Streams the expense items for a given date, ordered by createdAt
  /// descending (matches the provider's live subscription behavior).
  Stream<List<ExpenseItem>> watchExpenses({
    required String uid,
    required String dateId,
  }) {
    return _userRef(uid)
        .collection('expenses')
        .doc(dateId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => ExpenseItem.fromFirestore(doc.id, doc.data(), dateId),
      )
          .toList(),
    );
  }

  /// Returns every expense-day document (dateId + total) for the user.
  Future<List<ExpenseDay>> getAllExpenseDays({required String uid}) async {
    try {
      final snapshot = await _userRef(uid).collection('expenses').get();

      return snapshot.docs.map((doc) {
        return ExpenseDay(
          dateId: doc.id,
          total: (doc.data()['total'] ?? 0).toDouble(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Returns all expense items for a given month (yyyy-MM), grouped by date.
  Future<Map<String, List<ExpenseItem>>> getMonthExpenses({
    required String uid,
    required String monthKey,
  }) async {
    final Map<String, List<ExpenseItem>> grouped = {};

    try {
      final expensesSnapshot = await _userRef(uid)
          .collection('expenses')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$monthKey-01')
          .where(FieldPath.documentId, isLessThan: '$monthKey-32')
          .get();

      for (final dateDoc in expensesSnapshot.docs) {
        final dateId = dateDoc.id;

        final itemsSnapshot = await dateDoc.reference
            .collection('items')
            .get();

        if (itemsSnapshot.docs.isEmpty) continue;

        final items = itemsSnapshot.docs.map((itemDoc) {
          return ExpenseItem.fromFirestore(itemDoc.id, itemDoc.data(), dateId);
        }).toList();

        grouped[dateId] = items;
      }

      return grouped;
    } catch (e) {
      return {};
    }
  }

  /// Returns the running total for a given date (yyyy-MM-dd).
  Future<double> getTotalForDate({
    required String uid,
    required String dateId,
  }) async {
    try {
      final doc = await _userRef(uid)
          .collection('expenses')
          .doc(dateId)
          .get();

      return (doc.data()?['total'] ?? 0).toDouble();
    } catch (e) {
      return 0;
    }
  }
  // ===========================================================================
  // EXTENDED READ METHODS
  // ---------------------------------------------------------------------------
  // NOT in the original rule-8 method list. Added so the Provider can drop
  // its `FirebaseFirestore` import entirely (getYearStats,
  // getMonthStatsForSelectedYear, getMonthStatsByMonth and
  // getExpensesGroupedByMonthForType were still calling `_firestore`
  // directly in the original provider). Behavior is copied exactly.
  // ===========================================================================

  Future<YearStats?> getYearStats({
    required String uid,
    required String year,
  }) async {
    try {
      final doc = await _userRef(uid)
          .collection('year_stats')
          .doc(year)
          .get();

      if (!doc.exists) return null;

      return YearStats.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<List<MonthStats>> getMonthStatsForYear({
    required String uid,
    required String year,
  }) async {
    try {
      final snapshot = await _userRef(uid)
          .collection('year_stats')
          .doc(year)
          .collection('months')
          .orderBy('month')
          .get();

      return snapshot.docs
          .map((doc) => MonthStats.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<MonthStats?> getMonthStatsByMonth({
    required String uid,
    required String year,
    required String month,
  }) async {
    try {
      final doc = await _userRef(uid)
          .collection('year_stats')
          .doc(year)
          .collection('months')
          .doc(month)
          .get();

      if (!doc.exists) return null;

      return MonthStats.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, List<ExpenseDay>>> getExpensesGroupedByMonthForType({
    required String uid,
    required String expenseTypeName,
  }) async {
    final Map<String, List<ExpenseDay>> grouped = {};

    final datesSnapshot = await _userRef(uid).collection('expenses').get();

    for (final dateDoc in datesSnapshot.docs) {
      final dateId = dateDoc.id;
      final monthKey = dateId.substring(0, 7);

      final itemsSnapshot = await _userRef(uid)
          .collection('expenses')
          .doc(dateId)
          .collection('items')
          .where('type', isEqualTo: expenseTypeName)
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

  /// Returns the current balance for a bank's month document, or `null` if
  /// the month document doesn't exist. Used by the Provider's pre-flight
  /// balance check (validateAndPrepareBankTransaction) so it doesn't need
  /// to touch Firestore directly. This is a plain read — the authoritative,
  /// race-safe balance check still happens inside addExpense()'s
  /// transaction via _validateBank().
  Future<double?> getBankMonthBalance({
    required String uid,
    required String bankId,
    required String monthId,
  }) async {
    final doc = await _bankMonthRef(
      uid: uid,
      bankId: bankId,
      monthId: monthId,
    ).get();

    if (!doc.exists) return null;

    return (doc.data()?['currentAmount'] ?? 0).toDouble();
  }

  // ===========================================================================
  // PRIVATE — REFERENCE BUILDERS
  // ===========================================================================

  bool _isCash(String? transactionTypeId) =>
      transactionTypeId == null || transactionTypeId == 'cash';

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  CollectionReference<Map<String, dynamic>> _usersCollection() =>
      _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _usersCollection().doc(uid);

  DocumentReference<Map<String, dynamic>> _bankRef({
    required String uid,
    required String bankId,
  }) => _userRef(uid).collection('bank').doc(bankId);

  DocumentReference<Map<String, dynamic>> _bankMonthRef({
    required String uid,
    required String bankId,
    required String monthId,
  }) => _bankRef(uid: uid, bankId: bankId).collection('monthAmount').doc(monthId);

  /// Groups the references needed by addExpense() so they aren't rebuilt
  /// repeatedly across helper methods.
  _ExpenseReferences _buildExpenseReferences({
    required String uid,
    required String dateId,
  }) {
    final userRef = _userRef(uid);
    final dateRef = userRef.collection('expenses').doc(dateId);
    final year = dateId.substring(0, 4);
    final month = dateId.substring(0, 7);
    final yearRef = userRef.collection('year_stats').doc(year);
    final monthRef = yearRef.collection('months').doc(month);

    return _ExpenseReferences(
      userRef: userRef,
      dateRef: dateRef,
      yearRef: yearRef,
      monthRef: monthRef,
      month: month,
    );
  }

  // ===========================================================================
  // PRIVATE — ADD EXPENSE HELPERS
  // ===========================================================================

  Future<void> _validateBank({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>>? bankRef,
    required DocumentReference<Map<String, dynamic>>? bankMonthRef,
    required double amount,
    required bool isCash,
  }) async {
    if (isCash) return;

    final bankSnap = await tx.get(bankRef!);
    final bankMonthSnap = await tx.get(bankMonthRef!);

    if (!bankSnap.exists) {
      throw Exception('Bank not found during deduction');
    }

    if (!bankMonthSnap.exists) {
      throw Exception('Bank month not found during deduction');
    }

    final currentBalance = (bankMonthSnap.data()?['currentAmount'] ?? 0)
        .toDouble();

    if (currentBalance < amount) {
      throw Exception('Insufficient balance during transaction');
    }
  }

  void _updateBankBalance({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>>? bankMonthRef,
    required bool isCash,
    required double delta,
  }) {
    if (isCash) return;
    _updateBankMonthAmount(tx: tx, bankMonthRef: bankMonthRef!, delta: delta);
  }

  void _createExpenseDocument({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> dateRef,
    required String title,
    required double amount,
    required String description,
    required String expenseTypeName,
    required String? transactionTypeId,
    required DateTime createdAt,
  }) {
    final itemRef = dateRef.collection('items').doc();
    tx.set(itemRef, {
      'title': title,
      'amount': amount,
      'description': description,
      'type': expenseTypeName,
      'transactionType': transactionTypeId,
      'createdAt': Timestamp.fromDate(createdAt),
    });
  }

  void _updateMonthStatsForAdd({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> monthRef,
    required String monthId,
    required String expenseTypeName,
    required double amount,
  }) {
    tx.set(monthRef, {
      'month': monthId,
      expenseTypeName: FieldValue.increment(amount),
      'grandTotal': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ===========================================================================
  // PRIVATE — EDIT EXPENSE HELPERS
  // ===========================================================================

  void _validateEditBankBalances({
    required bool sameBank,
    required double diff,
    required double newAmount,
    required DocumentSnapshot<Map<String, dynamic>>? sameBankMonthSnap,
    required DocumentReference<Map<String, dynamic>>? newBankMonthRef,
    required DocumentSnapshot<Map<String, dynamic>>? newBankMonthSnap,
  }) {
    if (sameBank &&
        diff != 0 &&
        sameBankMonthSnap != null &&
        sameBankMonthSnap.exists) {
      final current = (sameBankMonthSnap.data()?['currentAmount'] ?? 0)
          .toDouble();
      if (diff > 0 && current < diff) {
        throw Exception('Insufficient balance during edit');
      }
    }

    if (!sameBank && newBankMonthRef != null) {
      if (newBankMonthSnap == null || !newBankMonthSnap.exists) {
        throw Exception('Target bank month missing');
      }
      final current = (newBankMonthSnap.data()?['currentAmount'] ?? 0)
          .toDouble();
      if (current < newAmount) {
        throw Exception('Insufficient balance in new bank');
      }
    }
  }

  void _updateExpenseItem({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> itemRef,
    required String title,
    required double amount,
    required String description,
    required String typeName,
    required String? transactionTypeId,
  }) {
    tx.update(itemRef, {
      'title': title,
      'amount': amount,
      'description': description,
      'type': typeName,
      'transactionType': transactionTypeId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _updateMonthStatsForEditSameType({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> monthRef,
    required String typeName,
    required double diff,
  }) {
    tx.set(monthRef, {
      typeName: FieldValue.increment(diff),
      'grandTotal': FieldValue.increment(diff),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _updateMonthStatsForEditTypeChanged({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> monthRef,
    required String oldType,
    required double oldAmount,
    required String newType,
    required double newAmount,
  }) {
    tx.set(monthRef, {
      oldType: FieldValue.increment(-oldAmount),
      newType: FieldValue.increment(newAmount),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ===========================================================================
  // PRIVATE — DELETE EXPENSE HELPERS
  // ===========================================================================

  void _deleteExpenseDocument({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> itemRef,
  }) {
    tx.delete(itemRef);
  }

  void _updateMonthStatsForDelete({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> monthRef,
    required String typeName,
    required double amount,
  }) {
    tx.set(monthRef, {
      typeName: FieldValue.increment(-amount),
      'grandTotal': FieldValue.increment(-amount),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ===========================================================================
  // PRIVATE — SHARED WRITE HELPERS
  // ===========================================================================

  void _updateDailyTotal({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> dateRef,
    required double delta,
    String? dateId,
  }) {
    final data = <String, dynamic>{
      if (dateId != null) 'date': dateId,
      'total': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    tx.set(dateRef, data, SetOptions(merge: true));
  }

  void _updateGrandTotal({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> userRef,
    required double delta,
  }) {
    tx.set(userRef, {
      'grandTotal': FieldValue.increment(delta),
    }, SetOptions(merge: true));
  }

  void _updateYearGrandTotal({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> yearRef,
    required double delta,
    bool includeUpdatedAt = true,
  }) {
    final data = <String, dynamic>{'grandTotal': FieldValue.increment(delta)};
    if (includeUpdatedAt) {
      data['updatedAt'] = FieldValue.serverTimestamp();
    }
    tx.set(yearRef, data, SetOptions(merge: true));
  }

  void _updateBankMonthAmount({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> bankMonthRef,
    required double delta,
  }) {
    tx.update(bankMonthRef, {
      'currentAmount': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Groups the Firestore references shared across addExpense()'s helper
/// methods so they are only built once per call.
class _ExpenseReferences {
  const _ExpenseReferences({
    required this.userRef,
    required this.dateRef,
    required this.yearRef,
    required this.monthRef,
    required this.month,
  });

  final DocumentReference<Map<String, dynamic>> userRef;
  final DocumentReference<Map<String, dynamic>> dateRef;
  final DocumentReference<Map<String, dynamic>> yearRef;
  final DocumentReference<Map<String, dynamic>> monthRef;
  final String month;
}
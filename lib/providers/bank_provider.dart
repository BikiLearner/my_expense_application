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
  final Map<String, List<BankMonthModel>> _bankMonths = {};
  String _entryKey(String bankId, String monthId) => '$bankId|$monthId';

  List<BankMonthModel> getBankMonths(String bankId) =>
      _bankMonths[bankId] ?? [];
  List<BankMonthEntry> getMonthEntries(
      String bankId,
      String monthId,
      ) {
    return _monthEntries[_entryKey(bankId, monthId)] ?? [];
  }

  // 🔹 Cache: bankId_monthId → entries
  final Map<String, List<BankMonthEntry>> _monthEntries = {};

// 🔹 Subscriptions
  final Map<String, StreamSubscription> _entrySubs = {};


  StreamSubscription? _sub;
  StreamSubscription? _monthSub;
  bool isLoading = false;

  BankProvider() {
    listenBanks();

  }


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
        'description': 'Initial amount',
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
//   Stream<List<BankMonthEntry>> streamMonthEntries(String bankId, String monthId) {
//     return _firestore
//         .collection('users')
//         .doc(uid)
//         .collection('bank')
//         .doc(bankId)
//         .collection('monthAmount')
//         .doc(monthId)
//         .collection('entries')
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs
//           .map((e) => BankMonthEntry.fromFirestore(e.id, e.data()))
//           .toList();
//     });
//   }


  void stopListeningMonthEntries(String bankId, String monthId) {
    final key = _entryKey(bankId, monthId);
    _entrySubs[key]?.cancel();
    _entrySubs.remove(key);
    _monthEntries.remove(key);
  }

  double getTotalMonthAmountOfThisMonth() {
    final now = DateTime.now();
    final currentMonthId =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    double total = 0;

    for (final bankMonths in _bankMonths.values) {
      for (final m in bankMonths) {
        if (m.id == currentMonthId) {
          total += m.totalAdded;
          break; // one month per bank
        }
      }
    }

    return total;
  }

  double? getTotalCurrentAmountMonthAmountOfThisMonth(){
    final now = DateTime.now();
    final currentMonthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    double total = 0;
    for (final bankMonths in _bankMonths.values) {
      for (final m in bankMonths) {
        if (m.id == currentMonthId) {
          total += m.currentAmount;
          break; // one month per bank
        }
      }
    }
    return total;

  }
  double getTotalThisMonthSurplus() {
    final now = DateTime.now();

    final prevMonthDate = DateTime(now.year, now.month - 1);
    final prevMonthId =
        '${prevMonthDate.year}-${prevMonthDate.month.toString().padLeft(2, '0')}';

    double total = 0;

    for (final bankMonths in _bankMonths.values) {
      for (final m in bankMonths) {
        if (m.id == prevMonthId) {
          total += m.currentAmount;
          break; // one month per bank
        }
      }
    }

    return total;
  }

  void listenMonthEntries({
    required String bankId,
    required String monthId,
  }) {
    final key = _entryKey(bankId, monthId);

    // Avoid duplicate listeners
    if (_entrySubs.containsKey(key)) return;

    final sub = _firestore
        .collection('users')
        .doc(uid)
        .collection('bank')
        .doc(bankId)
        .collection('monthAmount')
        .doc(monthId)
        .collection('entries')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _monthEntries[key] = snapshot.docs
          .map((e) => BankMonthEntry.fromFirestore(e.id, e.data()))
          .toList();

      notifyListeners();
    });

    _entrySubs[key] = sub;
  }



  void listenBankMonths(String bankId) {
    _monthSub?.cancel();

    _monthSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('bank')
        .doc(bankId)
        .collection('monthAmount')
        .snapshots()
        .listen((snapshot) {
      _bankMonths[bankId] = snapshot.docs
          .map((e) => BankMonthModel.fromFirestore(e.id, e.data()))
          .toList();

      notifyListeners();
    });
  }

  // 🔹 Stream monthAmount for a bank
  // Stream<List<BankMonthModel>> streamBankMonths(String bankId) {
  //   return _firestore
  //       .collection('users')
  //       .doc(uid)
  //       .collection('bank')
  //       .doc(bankId)
  //       .collection('monthAmount')
  //       .snapshots()
  //       .map((snapshot) {
  //     return snapshot.docs
  //         .map((e) => BankMonthModel.fromFirestore(e.id, e.data()))
  //         .toList();
  //   });
  // }

  double getSurplus({
    required String bankId,
    required String monthId,
  }) {
    final months = _bankMonths[bankId] ?? [];

    final currentIndex = months.indexWhere((m) => m.id == monthId);
    if (currentIndex <= 0) return 0;

    final previous = months[currentIndex - 1].currentAmount;

    return previous;
  }

// 🔹 Add / update monthAmount
// 🔹 Add amount to current month (MULTIPLE TIMES SAFE)
  Future<void> addMonthAmount({
    required String bankId,
    required double amount,
    String? description = "Not Provided"
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
        'description': description,
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

  String getTransactionBankName(String? id) {
    debugPrint('🔍 getTransactionBankName called with id: $id');

    // 🟢 Cash / null fallback
    if (id == null || id == 'cash') {
      debugPrint('✅ Transaction type is cash / null');
      return 'Cash';
    }

    // 🟡 Bank list not ready yet
    if (_banks.isEmpty) {
      debugPrint(
        '⏳ Bank list not loaded yet. Returning Loading... (id=$id)',
      );
      return 'Loading...';
    }

    // 🔵 Try to find bank
    final matches = _banks.where((b) => b.id == id);

    if (matches.isNotEmpty) {
      final bankName = matches.first.bankName;
      debugPrint(
        '🏦 Bank found for id=$id → name="$bankName"',
      );
      return bankName;
    }

    // 🔴 Bank deleted / stale transactionType
    debugPrint(
      '❌ No bank found for id=$id. '
          'This may be a deleted bank or stale transactionType.',
    );

    return 'Unknown Bank';
  }



  @override
  void dispose() {
    _sub?.cancel(); // bank list

    for (final sub in _entrySubs.values) {
      sub.cancel();
    }

    _entrySubs.clear();
    _monthEntries.clear();

    super.dispose();
  }
}

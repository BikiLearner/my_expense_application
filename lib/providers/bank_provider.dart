import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expence_app/services/audio_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/bank_model.dart';
import '../models/bank_month_entry_model.dart';
import '../models/bank_month_model.dart';

class BankProvider extends ChangeNotifier
{
  final _firestore = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;
  final Map<String, StreamSubscription> _currentMonthSubs = {};
  List<BankModel> _banks = [];
  List<BankModel> get banks => _banks;
  final Map<String, List<BankMonthModel>> _bankMonths = {};
  String _entryKey(String bankId, String monthId) => '$bankId|$monthId';

  List<BankMonthModel> getBankMonths(String bankId) =>
  _bankMonths[bankId] ?? [];
  List<BankMonthEntry> getMonthEntries(
    String bankId,
    String monthId,
  ) 
  {
    return _monthEntries[_entryKey(bankId, monthId)] ?? [];
  }

  // 🔹 Cache: bankId_monthId → entries
  final Map<String, List<BankMonthEntry>> _monthEntries = {};

  // 🔹 Subscriptions
  final Map<String, StreamSubscription> _entrySubs = {};

  String get currentMonthId 
  {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  StreamSubscription? _sub;
  StreamSubscription? _monthSub;
  bool isLoading = false;

  BankProvider()
  {
    listenBanks();

  }

  double getCurrentMonthBalance(String bankId) 
  {
    final now = DateTime.now();
    final monthId =
      '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final months = _bankMonths[bankId];
    if (months == null) return 0;

    final match = months.firstWhere(
      (m) => m.id == monthId,
      orElse: () => BankMonthModel.empty(monthId),
    );

    return match.currentAmount;
  }

  void listenBanks() 
  {
    isLoading = true;
    notifyListeners();

    _sub?.cancel();
    _sub = _firestore
      .collection('users')
      .doc(uid)
      .collection('bank')
      .snapshots()
      .listen((snapshot)
        {
          _banks = snapshot.docs
            .map((e) => BankModel.fromFirestore(e.id, e.data()))
            .toList();

          for (final bank in _banks)
          {
            listenCurrentBankMonth(bank.id);
          }

          isLoading = false;
          notifyListeners();
        });
  }

  void listenCurrentBankMonth(String bankId) 
  {
    final key = '$bankId|$currentMonthId';

    // 🚫 Avoid duplicate listeners
    if (_currentMonthSubs.containsKey(key)) return;

    final sub = _firestore
      .collection('users')
      .doc(uid)
      .collection('bank')
      .doc(bankId)
      .collection('monthAmount')
      .doc(currentMonthId)
      .snapshots()
      .listen((doc)
        {
          if (!doc.exists) 
          {
            _bankMonths[bankId] = [];
          } else 
          {
            _bankMonths[bankId] = [
              BankMonthModel.fromFirestore(doc.id, doc.data()!)
            ];
          }
          notifyListeners();
        });

    _currentMonthSubs[key] = sub;
  }

  Future<void> addBank({
    required String bankName,
    required double amount,
  }) async
  {
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

    await _firestore.runTransaction((tx) async
      {
        // 1️⃣ Create bank document
        tx.set(bankRef, 
          {
            'bankName': bankName,
            'addedDate': Timestamp.now(),
          });

        // 2️⃣ Create initial month summary
        tx.set(monthRef, 
          {
            'totalAdded': amount,
            'currentAmount': amount,
            'surplusPreviousMonth':0,
            'incomeThisMonth':amount,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

        // 3️⃣ Create initial entry (history)
        tx.set(entryRef, 
          {
            'amount': amount,
            'description': 'Initial amount',
            'createdAt': FieldValue.serverTimestamp(),
          });
      });
  }

  BankMonthModel? getCurrentMonthForBank(String bankId) 
  {
    final now = DateTime.now();
    final currentMonthId =
      '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final months = _bankMonths[bankId];
    if (months == null) return null;

    return months.firstWhere(
      (m) => m.id == currentMonthId,
      orElse: () => BankMonthModel(
        id: currentMonthId,
        totalAdded: 0,
        currentAmount: 0,
        updatedAt: null, surplusPreviousMonth: 0, incomeThisMonth: 0,
      ),
    );
  }

  Future<void> editBankMonth({
    required String bankId,
    required String monthId, // yyyy-MM
    required double totalAdded,
    required double incomeThisMonth,
    required double surplusPreviousMonth,
    required double currentAmount,
  }) async
  {
    final bankRef = _firestore
      .collection('users')
      .doc(uid)
      .collection('bank')
      .doc(bankId);

    final monthRef =
      bankRef.collection('monthAmount').doc(monthId);

    await _firestore.runTransaction((tx) async
      {
        final monthSnap = await tx.get(monthRef);

        if (!monthSnap.exists) 
        {
          throw Exception('❌ Month does not exist, cannot edit');
        }

        // 🔒 Single source of truth update
        tx.update(monthRef, 
          {
            'totalAdded': totalAdded,
            'incomeThisMonth': incomeThisMonth,
            'surplusPreviousMonth': surplusPreviousMonth,
            'currentAmount': currentAmount,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      });

    // 🔄 Update local cache so UI refreshes instantly
    final months = _bankMonths[bankId];
    if (months != null) 
    {
      final index = months.indexWhere((m) => m.id == monthId);
      if (index != -1) 
      {
        months[index] = BankMonthModel(
          id: monthId,
          totalAdded: totalAdded,
          incomeThisMonth: incomeThisMonth,
          surplusPreviousMonth: surplusPreviousMonth,
          currentAmount: currentAmount,
          updatedAt: Timestamp.now(),
        );
      }
    }

    notifyListeners();
  }

  double get totalBankBalance 
  {
    final now = DateTime.now();
    final currentMonthId =
      '${now.year}-${now.month.toString().padLeft(2, '0')}';

    double total = 0;

    for (final bankMonths in _bankMonths.values)
    {
      for (final m in bankMonths)
      {
        if (m.id == currentMonthId) 
        {
          total += m.currentAmount;
          break; // one month per bank
        }
      }
    }

    return total;
  }

  Future<void> updateBank({
    required String bankId,
    required String bankName,
  }) async
  {
    await _firestore
      .collection('users')
      .doc(uid)
      .collection('bank')
      .doc(bankId)
      .update(
      {
        'bankName': bankName,
      });
  }

  void stopListeningMonthEntries(String bankId, String monthId) 
  {
    final key = _entryKey(bankId, monthId);
    _entrySubs[key]?.cancel();
    _entrySubs.remove(key);
    _monthEntries.remove(key);
  }

  double getTotalMonthAmountOfThisMonth() 
  {
    final now = DateTime.now();
    final currentMonthId =
      '${now.year}-${now.month.toString().padLeft(2, '0')}';

    double total = 0;

    for (final bankMonths in _bankMonths.values)
    {
      for (final m in bankMonths)
      {
        if (m.id == currentMonthId) 
        {
          total += m.totalAdded;
          break; // one month per bank
        }
      }
    }

    return total;
  }

  double? getTotalCurrentAmountMonthAmountOfThisMonth() 
  {
    final now = DateTime.now();
    final currentMonthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    double total = 0;
    for (final bankMonths in _bankMonths.values)
    {
      for (final m in bankMonths)
      {
        if (m.id == currentMonthId) 
        {
          total += m.currentAmount;
          break; // one month per bank
        }
      }
    }
    return total;

  }
  double getTotalThisMonthSurplus() 
  {
    final now = DateTime.now();
    final currentMonthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    double total = 0;

    for (final bankMonths in _bankMonths.values)
    {
      for (final m in bankMonths)
      {
        if (m.id == currentMonthId)
        {
          total += m.surplusPreviousMonth;
          break; // one month per bank
        }
      }
    }

    return total;
  }

  void listenMonthEntries({
    required String bankId,
    required String monthId,
  }) 
  {
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
      .listen((snapshot)
        {
          _monthEntries[key] = snapshot.docs
            .map((e) => BankMonthEntry.fromFirestore(e.id, e.data()))
            .toList();

          notifyListeners();
        });

    _entrySubs[key] = sub;
  }

  void listenBankMonths(String bankId) 
  {
    _monthSub?.cancel();

    _monthSub = _firestore
      .collection('users')
      .doc(uid)
      .collection('bank')
      .doc(bankId)
      .collection('monthAmount')
      .snapshots()
      .listen((snapshot)
        {
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
  }) 
  {
    final months = _bankMonths[bankId] ?? [];

    final currentIndex = months.indexWhere((m) => m.id == monthId);
    if (currentIndex <= 0) return 0;

    final previous = months[currentIndex - 1].currentAmount;

    return previous;
  }


  // Add this method to your BankProvider class

  /// 🔄 Transfer money between banks
  Future<void> transferBetweenBanks({
    required BuildContext context,
    required String fromBankId,
    required String toBankId,
    required double amount,
    required String description,
  }) async {
    final now = DateTime.now();
    final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final fromBankRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('bank')
        .doc(fromBankId);

    final toBankRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('bank')
        .doc(toBankId);

    final fromMonthRef = fromBankRef.collection('monthAmount').doc(monthId);
    final toMonthRef = toBankRef.collection('monthAmount').doc(monthId);

    // 🔹 Create transfer entry references
    final fromEntryRef = fromMonthRef.collection('entries').doc();
    final toEntryRef = toMonthRef.collection('entries').doc();

    try {
      await _firestore.runTransaction((tx) async {
        // 🔹 Read current states
        final fromBankSnap = await tx.get(fromBankRef);
        final toBankSnap = await tx.get(toBankRef);
        final fromMonthSnap = await tx.get(fromMonthRef);
        final toMonthSnap = await tx.get(toMonthRef);

        // ❌ Validate banks exist
        if (!fromBankSnap.exists || !toBankSnap.exists) {
          throw Exception('One or both banks not found');
        }

        // ❌ Validate source month exists
        if (!fromMonthSnap.exists) {
          throw Exception('Source bank month not initialized');
        }

        // ❌ Validate destination month exists
        if (!toMonthSnap.exists) {
          throw Exception('Destination bank month not initialized');
        }

        // 🔹 Check sufficient balance in source bank
        final fromCurrentAmount =
        (fromMonthSnap.data()?['currentAmount'] ?? 0).toDouble();

        if (fromCurrentAmount < amount) {
          throw Exception('Insufficient balance in source bank');
        }

        // 🔹 Deduct from source bank
        tx.update(fromMonthRef, {
          'currentAmount': FieldValue.increment(-amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 🔹 Add transfer-out entry to source bank
        tx.set(fromEntryRef, {
          'amount': -amount, // Negative to show outgoing
          'description': 'Transfer to: $description',
          'type': 'transfer_out',
          'targetBankId': toBankId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 🔹 Add to destination bank
        tx.update(toMonthRef, {
          'currentAmount': FieldValue.increment(amount),
          'totalAdded': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 🔹 Add transfer-in entry to destination bank
        tx.set(toEntryRef, {
          'amount': amount,
          'description': 'Transfer from: $description',
          'type': 'transfer_in',
          'sourceBankId': fromBankId,
          'createdAt': FieldValue.serverTimestamp(),
        });
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

  
  Future<void> deductForLent({
    required String bankId,
    required double amount,
    required String description,
  }) async {
    final now = DateTime.now();
    final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final bankRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('bank')
        .doc(bankId);

    final monthRef = bankRef.collection('monthAmount').doc(monthId);
    final entryRef = monthRef.collection('entries').doc();

    await _firestore.runTransaction((tx) async {
      final monthSnap = await tx.get(monthRef);
      if (!monthSnap.exists) {
        throw Exception('Bank month not initialized');
      }

      final current =
      (monthSnap.data()?['currentAmount'] ?? 0).toDouble();

      if (current < amount) {
        throw Exception('Insufficient balance');
      }

      tx.update(monthRef, {
        'currentAmount': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(entryRef, {
        'amount': -amount,
        'type': 'lent_out',
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }


  Future<void> addMonthAmount({
    required String bankId,
    required double amount,
    String? description = "Not Provided"
  }) async
  {
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

    await _firestore.runTransaction((tx) async
      {
        // final bankSnap = await tx.get(bankRef);
        final monthSnap = await tx.get(monthRef);

        final currentBankAmount =
          (monthSnap.data()?['currentAmount'] ?? 0).toDouble();

        final monthTotal =
          (monthSnap.data()?['totalAdded'] ?? 0).toDouble();

        final newBankAmount = currentBankAmount + amount;
        final newMonthTotal = monthTotal + amount;

        // 1️⃣ Add entry (history)
        tx.set(entryRef, 
          {
            'amount': amount,
            'description': description,
            'createdAt': FieldValue.serverTimestamp(),
          });

        // 2️⃣ Update / create month summary
        tx.set(monthRef, 
          {
            'totalAdded': newMonthTotal,
            'currentAmount': newBankAmount,
            'incomeThisMonth':amount,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

        // 3️⃣ Update bank totals
        tx.update(bankRef, 
          {
            'currentAmount': newBankAmount,
            'totalAmountWhenAdded': FieldValue.increment(amount),
          });
      });
  }

  Future<void> _showSurplusWarningDialog(
    BuildContext context,
    double surplus,
  ) async
  {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx)
      {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// 🔥 HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFff416c),
                      Color(0xFFff4b2b),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'BHAAG BSDK 😂😂',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              /// 🧠 CONTENT
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Pichhle mahine ka paisa tune already add kar liya hai 💀\n\n'
                      '₹${surplus.toStringAsFixed(2)} phir se surplus bana raha hai.\n'
                      'Kitni baar karega bhai? 🤦‍♂️\n\n'
                      'Ek baar verify kar le, phir aage badh.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ✅ ACTION BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF64FFDA),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 6,
                        ),
                        onPressed: () async
                        {
                          var audioService = AudioPlayerService();
                          await audioService.play('audio/bhaag_yehasa_audio.mp3', isAsset: true);
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'SAMJH GAYA 😭',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> ensureBankMonthExistsWithDialog({
    required BuildContext context,
    required String bankId,
    required String monthId,
    bool showWaring = false // yyyy-MM
  }) async
  {
    final bankRef = _firestore
      .collection('users')
      .doc(uid)
      .collection('bank')
      .doc(bankId);

    final monthRef =
      bankRef.collection('monthAmount').doc(monthId);

    final bankSnap = await bankRef.get();
    if (!bankSnap.exists) return false;

    final monthSnap = await monthRef.get();
    if (monthSnap.exists) 
    {
      if (showWaring) 
      {
        final surplus = (monthSnap.data()?['surplusPreviousMonth'] ?? 0).toDouble();
        if (surplus > 0) 
        {
          _showSurplusWarningDialog(context, surplus);
        }
      }

      return true;
    }

    // 🔹 Previous month (year change handled automatically)
    final parts = monthId.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    final prevMonthDate = DateTime(year, month - 1);
    final prevMonthId =
      '${prevMonthDate.year}-${prevMonthDate.month.toString().padLeft(2, '0')}';

    final prevMonthRef =
      bankRef.collection('monthAmount').doc(prevMonthId);

    double previousClosing = 0.0;

    final prevMonthSnap = await prevMonthRef.get();
    if (prevMonthSnap.exists) 
    {
      previousClosing =
      (prevMonthSnap.data()?['currentAmount'] ?? 0).toDouble();
    }

    // 🔹 Controllers (USER CONTROL)
    final surplusController =
      TextEditingController(text: previousClosing.toStringAsFixed(2));
    final totalAddedController =
      TextEditingController(text: previousClosing.toStringAsFixed(2));
    final currentAmountController =
      TextEditingController(text: previousClosing.toStringAsFixed(2));

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx)
      {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Initialize Bank Month',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('Surplus from Previous Month', surplusController),
              _field('Total Amount Added', totalAddedController),
              _field('Current Amount', currentAmountController),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return false;

    final surplusValue =
      double.tryParse(surplusController.text) ?? 0;
    final totalAdded =
      double.tryParse(totalAddedController.text) ?? 0;
    final currentAmount =
      double.tryParse(currentAmountController.text) ?? surplusValue;

    // 🔒 Atomic write
    await _firestore.runTransaction((tx) async
      {
        tx.set(monthRef, 
          {
            'surplusPreviousMonth': surplusValue, // carry from prev month
            'totalAdded': totalAdded,
            'incomeThisMonth':0,
            'currentAmount': currentAmount,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      });

    return true;
  }

  Widget _field(
    String label,
    TextEditingController controller, {
      bool enabled = true,
    }) 
  {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  String getTransactionBankName(String? id) 
  {
    debugPrint('🔍 getTransactionBankName called with id: $id');

    // 🟢 Cash / null fallback
    if (id == null || id == 'cash') 
    {
      debugPrint('✅ Transaction type is cash / null');
      return 'Cash';
    }

    // 🟡 Bank list not ready yet
    if (_banks.isEmpty) 
    {
      debugPrint(
        '⏳ Bank list not loaded yet. Returning Loading... (id=$id)',
      );
      return 'Loading...';
    }

    // 🔵 Try to find bank
    final matches = _banks.where((b) => b.id == id);

    if (matches.isNotEmpty) 
    {
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
  void dispose() 
  {
    _sub?.cancel(); // bank list

    for (final sub in _entrySubs.values)
    {
      sub.cancel();
    }

    _entrySubs.clear();
    _monthEntries.clear();

    super.dispose();
  }
}

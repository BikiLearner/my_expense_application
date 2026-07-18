import 'dart:async';

import 'package:expence_app/core/services/session_maganger.dart';
import 'package:expence_app/features/bank/domain/repository/bank_repository.dart';
import 'package:expence_app/shared/dialogs/app_loader_dialog.dart';
import 'package:expence_app/shared/dialogs/show_surplus_problem_dialog.dart';
import 'package:flutter/material.dart';

import '../../../../shared/dialogs/bank_month_init_dialog.dart';
import '../../data/model/bank_model.dart';
import '../../data/model/bank_month_entry_model.dart';
import '../../data/model/bank_month_model.dart';

class BankProvider extends ChangeNotifier {
  String? get uid => SessionManager.instance.uid;

  List<BankModel> _banks = [];

  List<BankModel> get banks => _banks;

  final Map<String, List<BankMonthModel>> _bankMonths = {};

  final Map<String, List<BankMonthEntry>> _monthEntries = {};

  List<BankMonthModel> getBankMonths(String bankId) =>
      _bankMonths[bankId] ?? [];

  final Map<String, StreamSubscription<List<BankMonthModel>>>
  _monthSubscriptions = {};

  List<BankMonthEntry> getMonthEntries(String bankId, String monthId) {
    return _monthEntries[_entryKey(bankId, monthId)] ?? [];
  }

  String _entryKey(String bankId, String monthId) => '$bankId|$monthId';

  String get currentMonthId {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  BankMonthModel? getCurrentBankMonth(String bankId) {
    return _bankMonths[bankId]?.cast<BankMonthModel?>().firstWhere(
      (month) => month!.id == currentMonthId,
      orElse: () => null,
    );
  }

  double getCurrentMonthBalance(String bankId) {
    return getCurrentBankMonth(bankId)?.currentAmount ?? 0.0;
  }

  double get totalMonthAmountOfThisMonth => getTotalMonthAmountOfThisMonth();

  double get totalThisMonthSurplus => getTotalThisMonthSurplus();

  double get totalCurrentAmountOfThisMonth =>
      getTotalCurrentAmountMonthAmountOfThisMonth();

  bool isLoading = false;

  final BankRepository _repository;

  BankProvider({required BankRepository repository})
    : _repository = repository {
    _initOrReInitBank();
  }

  Future<void> _initOrReInitBank() async {
    await fetchBanks();
    // await fetchBankMonthAmount();
    await startBankMonthListeners();
  }

  Future<void> fetchBanks() async {
    try {
      _banks = await _repository.fetchBanks();
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to fetch banks: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> fetchBankMonthAmount() async {
    try {
      await Future.wait(
        _banks.map((bank) async {
          final months = await _repository.fetchBankMonthAmount(bank.id);

          _bankMonths[bank.id] = months;
        }),
      );

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to fetch bank months: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> startBankMonthListeners() async {
    for (final bank in _banks) {
      _monthSubscriptions[bank.id]?.cancel();

      _monthSubscriptions[bank.id] = _repository
          .streamBankMonthAmount(bank.id)
          .listen((months) {
            _bankMonths[bank.id] = months;
            notifyListeners();
          });
    }
  }

  Future<void> fetchBankMonthEntries({
    required String bankId,
    required String monthId,
  }) async {
    try {
      final entries = await _repository.fetchBankMonthEntries(
        bankId: bankId,
        monthId: monthId,
      );

      _monthEntries[_entryKey(bankId, monthId)] = entries;

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to fetch bank month entries: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> addBank({
    required String bankName,
    required double amount,
    required BuildContext context,
  }) async {
    AppLoader.show(context, message: 'Adding bank...');

    try {
      await _repository.addBank(bankName: bankName, amount: amount);
      await fetchBanks();
    } catch (e) {
      debugPrint('❌ Failed to add bank: $e');

      // Optional: Show an error message to the user
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add bank: $e')));
      }
    } finally {
      AppLoader.hide();
    }
  }

  BankMonthModel? getCurrentMonthForBank(String bankId) {
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
        updatedAt: null,
        surplusPreviousMonth: 0,
        incomeThisMonth: 0,
      ),
    );
  }

  Future<void> editBankMonth({
    required String bankId,
    required String monthId,
    required double totalAdded,
    required double incomeThisMonth,
    required double surplusPreviousMonth,
    required double currentAmount,
  }) async {
    try {
      await _repository.editBankMonth(
        bankId: bankId,
        monthId: monthId,
        totalAdded: totalAdded,
        incomeThisMonth: incomeThisMonth,
        surplusPreviousMonth: surplusPreviousMonth,
        currentAmount: currentAmount,
      );

      await fetchBankMonthAmount();

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to edit bank month: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  double getTotalMonthAmountOfThisMonth() {
    return _bankMonths.values
        .expand((months) => months)
        .where((month) => month.id == currentMonthId)
        .fold(0.0, (sum, month) => sum + month.totalAdded);
  }

  double getTotalThisMonthSurplus() {
    return _bankMonths.values
        .expand((months) => months)
        .where((month) => month.id == currentMonthId)
        .fold(0.0, (sum, month) => sum + month.surplusPreviousMonth);
  }

  double getTotalCurrentAmountMonthAmountOfThisMonth() {
    return _bankMonths.values
        .expand((months) => months)
        .where((month) => month.id == currentMonthId)
        .fold(0.0, (sum, month) => sum + month.currentAmount);
  }

  double get totalBankBalance {
    final now = DateTime.now();
    final currentMonthId =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

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

  Future<void> updateBank({
    required String bankId,
    required String bankName,
  }) async {
    _repository.updateBank(bankId: bankId, bankName: bankName);
  }

  /// 🔄 Transfer money between banks
  Future<void> transferBetweenBanks({
    required BuildContext context,
    required String fromBankId,
    required String toBankId,
    required double amount,
    required String description,
  }) async {
    // 1️⃣ Validate: Prevent transferring negative amounts or transferring to the exact same bank
    if (amount <= 0 || fromBankId == toBankId) return;

    // 2️⃣ Lock the UI so the user can't double-tap the transfer button
    AppLoader.show(context, message: 'Transferring funds...');

    try {
      // 3️⃣ Added 'await' (Crucial for the try/catch to actually intercept Firebase errors)
      await _repository.transferBetweenBanks(
        fromBankId: fromBankId,
        toBankId: toBankId,
        amount: amount,
        description: description,
      );

      // Optional: Pop the transfer dialog on success
      // if (context.mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ Failed to transfer funds: $e');

      // 4️⃣ Safely show the error to the user
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to transfer funds: $e')));
      }
    } finally {
      // 5️⃣ Guarantee the loader is hidden, even if the transfer fails
      AppLoader.hide();
    }
  }

  Future<void> addMonthAmount({
    required BuildContext context, // 👈 Added context for UI feedback
    required String bankId,
    required double amount,
    String? description = "Not Provided",
  }) async {
    // Prevent zero or negative amounts from making unnecessary network calls
    if (amount <= 0) return;

    // 1️⃣ Block the screen with a loader
    AppLoader.show(context, message: 'Adding funds...');

    try {
      await _repository.addMonthAmount(
        bankId: bankId,
        amount: amount,
        description:
            description, // 👈 Make sure you pass the description to the repo!
      );
    } catch (e) {
      debugPrint('❌ Failed to add month amount: $e');

      // 3️⃣ Safely show an error to the user
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add funds: $e')));
      }
    } finally {
      AppLoader.hide();
    }
  }

  Future<bool> ensureBankMonthExistsWithDialog({
    required BuildContext context,
    required String bankId,
    bool showWaring = false,
  }) async {
    // 1️⃣ Check database status via Repository
    final status = await _repository.checkBankAndMonthStatus(bankId: bankId);

    if (!status.bankExists) return false;

    // 2️⃣ If month exists, show warning if needed and return
    if (status.monthExists) {
      if (showWaring && status.surplus > 0) {
        if (!context.mounted) return true;
        ShowSurplusProblemDialog.show(context, status.surplus);
      }
      return true;
    }

    // 3️⃣ Month doesn't exist, fetch previous month's closing balance
    final previousClosing = await _repository.getPreviousMonthClosing(
      bankId: bankId,
    );

    // 4️⃣ Show the UI Dialog to the user
    if (!context.mounted) return false;

    AppLoader.pause();

    final userInput = await BankInitializeDialog.show(
      context: context,
      previousClosing: previousClosing,
    );

    // If user hit 'Cancel' in the dialog, abort
    if (userInput == null) return false;

    // 5️⃣ Save the new month to Firestore
    await _repository.initializeBankMonth(
      bankId: bankId,
      surplusValue: userInput.surplus,
      totalAdded: userInput.totalAdded,
      currentAmount: userInput.currentAmount,
    );
    await fetchBankMonthAmount();
    return true;
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
      debugPrint('⏳ Bank list not loaded yet. Returning Loading... (id=$id)');
      return 'Loading...';
    }

    // 🔵 Try to find bank
    final matches = _banks.where((b) => b.id == id);

    if (matches.isNotEmpty) {
      final bankName = matches.first.bankName;
      debugPrint('🏦 Bank found for id=$id → name="$bankName"');
      return bankName;
    }

    // 🔴 Bank deleted / stale transactionType
    debugPrint(
      '❌ No bank found for id=$id. '
      'This may be a deleted bank or stale transactionType.',
    );

    return 'Unknown Bank';
  }
}

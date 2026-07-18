import '../../data/model/bank_model.dart';
import '../../data/model/bank_month_entry_model.dart';
import '../../data/model/bank_month_model.dart';

/// Abstract repository defining all data operations for the Bank feature.
/// This strictly handles data—no BuildContext, no Dialogs, no UI logic.
abstract class BankRepository {

  /// Create a new bank and its initial month and entry.
  Future<void> addBank({required String bankName, required double amount});

  /// Update the name of an existing bank.
  Future<void> updateBank({required String bankId, required String bankName});

  /// Edit the summary of a specific bank month.
  Future<void> editBankMonth({
    required String bankId,
    required String monthId,
    required double totalAdded,
    required double incomeThisMonth,
    required double surplusPreviousMonth,
    required double currentAmount,
  });

  /// Add income/funds to an existing bank month.
  Future<void> addMonthAmount({
    required String bankId,
    required double amount,
    String? description,
  });

  /// Transfer money between two banks atomically.
  Future<void> transferBetweenBanks({
    required String fromBankId,
    required String toBankId,
    required double amount,
    required String description,
  });

  Future<List<BankModel>> fetchBanks();
  Future<List<BankMonthModel>> fetchBankMonthAmount(String bankId);
  Future<List<BankMonthEntry>> fetchBankMonthEntries({
    required String bankId,
    required String monthId,
  });

  Future<({bool bankExists, bool monthExists, double surplus})>

  checkBankAndMonthStatus({required String bankId});

  Future<double> getPreviousMonthClosing({required String bankId});
  Stream<List<BankMonthModel>> streamBankMonthAmount(String bankId);

  /// Balance of a bank's month document, or `null` if it doesn't exist.
  /// Used for the Provider's pre-flight balance check.
  Future<double?> getBankMonthBalance({required String bankId});

  /// and then pass them to this pure data function).
  Future<void> initializeBankMonth({
    required String bankId,
    required double surplusValue,
    required double totalAdded,
    required double currentAmount,
  });
}

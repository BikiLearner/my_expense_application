import 'package:expence_app/features/bank/data/model/bank_model.dart';
import 'package:expence_app/features/bank/data/model/bank_month_entry_model.dart';
import 'package:expence_app/features/bank/data/model/bank_month_model.dart';
import 'package:expence_app/features/bank/domain/repository/bank_repository.dart';

import '../datasource/bank_datasource.dart';

class BankRepositoryImpl implements BankRepository {
  BankRepositoryImpl({BankDatasource? datasource})
    : _datasource = datasource ?? BankDatasource();

  final BankDatasource _datasource;

  @override
  Future<void> addBank({required String bankName, required double amount}) {
    return _datasource.addBank(bankName: bankName, amount: amount);
  }

  @override
  Future<void> addMonthAmount({
    required String bankId,
    required double amount,
    String? description,
  }) {
    return _datasource.addMonthAmount(bankId: bankId, amount: amount);
  }

  @override
  Future<void> editBankMonth({
    required String bankId,
    required String monthId,
    required double totalAdded,
    required double incomeThisMonth,
    required double surplusPreviousMonth,
    required double currentAmount,
  }) {
    return _datasource.editBankMonth(
      bankId: bankId,
      monthId: monthId,
      totalAdded: totalAdded,
      incomeThisMonth: incomeThisMonth,
      surplusPreviousMonth: surplusPreviousMonth,
      currentAmount: currentAmount,
    );
  }

  @override
  Future<void> initializeBankMonth({
    required String bankId,
    required double surplusValue,
    required double totalAdded,
    required double currentAmount,
  }) {
    return _datasource.initializeBankMonth(
      bankId: bankId,
      surplusValue: surplusValue,
      totalAdded: totalAdded,
      currentAmount: currentAmount,
    );
  }

  @override
  Future<void> transferBetweenBanks({
    required String fromBankId,
    required String toBankId,
    required double amount,
    required String description,
  }) {
    return _datasource.transferBetweenBanks(
      fromBankId: fromBankId,
      toBankId: toBankId,
      amount: amount,
      description: description,
    );
  }

  @override
  Future<List<BankModel>> fetchBanks() {
    return _datasource.fetchBanks();
  }

  @override
  Future<List<BankMonthModel>> fetchBankMonthAmount(String bankId) {
    return _datasource.fetchBankMonthAmount(bankId);
  }

  @override
  Stream<List<BankMonthModel>> streamBankMonthAmount(String bankId) {
    return _datasource.streamBankMonthAmount(bankId);
  }

  @override
  Future<List<BankMonthEntry>> fetchBankMonthEntries({
    required String bankId,
    required String monthId,
  }) {
    return _datasource.fetchBankMonthEntries(bankId: bankId, monthId: monthId);
  }

  @override
  Future<double?> getBankMonthBalance({required String bankId}) {
    return _datasource.getBankMonthBalance(bankId: bankId);
  }

  @override
  Future<void> updateBank({required String bankId, required String bankName}) {
    // TODO: implement updateBank
    throw UnimplementedError();
  }

  @override
  Future<({bool bankExists, bool monthExists, double surplus})>
  checkBankAndMonthStatus({required String bankId}) {
    return _datasource.checkBankAndMonthStatus(bankId: bankId);
  }

  @override
  Future<double> getPreviousMonthClosing({required String bankId}) {
    return _datasource.getPreviousMonthClosing(bankId: bankId);
  }
}

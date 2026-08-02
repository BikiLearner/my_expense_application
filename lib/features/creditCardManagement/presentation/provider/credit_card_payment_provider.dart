import 'package:expence_app/features/creditCardManagement/data/model/billing_cycle_model.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card_expense_item_model.dart';
import 'package:expence_app/features/creditCardManagement/domain/repository/credit_repo.dart';
import 'package:expence_app/features/expense/domain/repository/expense_repository.dart';
import 'package:flutter/cupertino.dart';

import '../../../bank/domain/repository/bank_repository.dart';

class CreditCardDetailsProvider extends ChangeNotifier {
  List<CreditExpenseItem> _creditCardExpenseByBillingCycle = [];
  List<BillingCycleModel> _billingCyclesPerCreditCard = [];

  List<BillingCycleModel> get billingCyclesPerCreditCard =>
      _billingCyclesPerCreditCard;
  CreditCardModel? _creditCard;
  CreditCardModel get creditCard => _creditCard!;

  BillingCycleModel? _billingCycleModel;

  List<CreditExpenseItem> get creditCardExpenseByBillingCycle =>
      _creditCardExpenseByBillingCycle;

  CreditRepository _creditRepository;
  BankRepository _bankRepository;
  ExpenseRepository _expenseRepository;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _expenseAmountCtrl;
  late final TextEditingController _interestCtrl;
  late final TextEditingController _lateFeeCtrl;
  late final TextEditingController _gstCtrl;
  late final TextEditingController _otherChargesCtrl;
  late final TextEditingController _totalPaidCtrl;


  double get highestCurrentMonth {
    if (_creditCardExpenseByBillingCycle.isEmpty) return 0.0;
    return _creditCardExpenseByBillingCycle
        .map((d) => d.amount)
        .reduce((a, b) => a > b ? a : b);
  }


  BillingCycleModel? get currentBillingCycle {
    if (_creditCard == null) return null;

    try {
      return _billingCyclesPerCreditCard.firstWhere(
            (e) => e.billingCycleId == _creditCard!.currentBillingCycleId,
      );
    } catch (_) {
      return null;
    }
  }
  CreditCardDetailsProvider({
    required CreditRepository repository,
    required BankRepository bankRepository,
    required ExpenseRepository expenseRepository,
    required CreditCardModel creditCard,
  }) : _creditRepository = repository,
       _bankRepository = bankRepository,
       _expenseRepository = expenseRepository,
       _creditCard = creditCard{
    fetchCreditCardDetails(
      creditCard.creditCardId
    );
  }

  void setBillingCycleId(BillingCycleModel billingCycleModel) {
    _billingCycleModel = billingCycleModel;
    if (_creditCard != null) {
      fetchCreditCardDetails(_creditCard!.creditCardId);
    } else {
      notifyListeners();
    }
  }


  Future<void> fetchCreditCardDetails(String? cardId) async {
    if (cardId == null) return;

    try {
      _billingCyclesPerCreditCard = await _creditRepository.fetchBillingCycles(
        creditCardId: cardId,
      );

      _billingCycleModel = currentBillingCycle;

      if (_billingCycleModel != null) {
        _creditCardExpenseByBillingCycle =
        await _creditRepository.fetchCreditExpensesByBillingCycleId(
          creditCardId: cardId,
          billingCycleId: _billingCycleModel!.billingCycleId,
        );
      }
    } catch (e) {
      debugPrint("Cannot fetch credit details $e");
    } finally {
      notifyListeners();
    }
  }
}

import 'package:expence_app/features/creditCardManagement/data/model/billing_cycle_model.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card_expense_item_model.dart';
import 'package:expence_app/features/creditCardManagement/domain/repository/credit_repo.dart';
import 'package:expence_app/features/expense/domain/repository/expense_repository.dart';
import 'package:flutter/cupertino.dart';

import '../../../bank/data/model/bank_model.dart';
import '../../../bank/domain/repository/bank_repository.dart';
import '../../data/model/credit_payment.dart';

class CreditCardDetailsProvider extends ChangeNotifier {
  List<CreditExpenseItem> _creditCardExpenseByBillingCycle = [];
  List<BillingCycleModel> _billingCyclesPerCreditCard = [];

  List<BillingCycleModel> get billingCyclesPerCreditCard =>
      _billingCyclesPerCreditCard;
  final CreditCardModel? _creditCard;

  CreditCardModel get creditCard => _creditCard!;

  BillingCycleModel? _billingCycleModel;

  List<CreditExpenseItem> get creditCardExpenseByBillingCycle =>
      _creditCardExpenseByBillingCycle;

  final CreditRepository _creditRepository;
  final ExpenseRepository _expenseRepository;

  CreditCardDetailsProvider({
    required CreditRepository repository,
    required BankRepository bankRepository,
    required ExpenseRepository expenseRepository,
    required CreditCardModel creditCard,
  }) : _creditRepository = repository,
       _expenseRepository = expenseRepository,
       _creditCard = creditCard {
    fetchCreditCardDetails(creditCard.creditCardId);

    expenseAmountCtrl.addListener(updateTheTotalAmountIfOtherValueChange);
    interestCtrl.addListener(updateTheTotalAmountIfOtherValueChange);
    lateFeeCtrl.addListener(updateTheTotalAmountIfOtherValueChange);
    gstCtrl.addListener(updateTheTotalAmountIfOtherValueChange);
    otherChargesCtrl.addListener(updateTheTotalAmountIfOtherValueChange);

    fetchCreditCardDetails(creditCard.creditCardId);
  }

  final formKey = GlobalKey<FormState>();
  final TextEditingController expenseAmountCtrl = TextEditingController();
  final TextEditingController interestCtrl = TextEditingController();
  final TextEditingController lateFeeCtrl = TextEditingController();
  final TextEditingController gstCtrl = TextEditingController();
  final TextEditingController otherChargesCtrl = TextEditingController();
  final TextEditingController totalPaidCtrl = TextEditingController();

  BankModel? _selectedBank;

  BankModel? get selectedBank => _selectedBank;

  DateTime _paymentDate = DateTime.now();

  DateTime get paymentDate => _paymentDate;

  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  double get highestCurrentMonth {
    if (_creditCardExpenseByBillingCycle.isEmpty) return 0.0;
    return _creditCardExpenseByBillingCycle
        .map((d) => d.amount)
        .reduce((a, b) => a > b ? a : b);
  }

  void paymentScreenFieldInit() {
    expenseAmountCtrl.text = currentBillingCycle?.totalAmount.toString() ?? "0";
    interestCtrl.text = '0';
    lateFeeCtrl.text = '0';
    gstCtrl.text = '0';
    otherChargesCtrl.text = '0';
    totalPaidCtrl.text = '0';
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

  void setBillingCycleId(BillingCycleModel billingCycleModel) {
    _billingCycleModel = billingCycleModel;
    if (_creditCard != null) {
      fetchCreditCardDetails(_creditCard!.creditCardId);
    } else {
      notifyListeners();
    }
  }

  void setSelectedBank(BankModel? bank) {
    _selectedBank = bank;
    notifyListeners();
  }

  void setPaymentDate(DateTime date) {
    _paymentDate = date;
    notifyListeners();
  }

  Future<void> fetchCreditCardDetails(String? cardId) async {
    if (cardId == null) return;

    try {
      _billingCyclesPerCreditCard = await _creditRepository.fetchBillingCycles(
        creditCardId: cardId,
      );

      _billingCycleModel = currentBillingCycle;

      if (_billingCycleModel != null) {
        _creditCardExpenseByBillingCycle = await _creditRepository
            .fetchCreditExpensesByBillingCycleId(
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
  void updateTheTotalAmountIfOtherValueChange() {
    final expenseAmount = _parsed(expenseAmountCtrl);
    final interest = _parsed(interestCtrl);
    final lateFee = _parsed(lateFeeCtrl);
    final gst = _parsed(gstCtrl);
    final otherCharges = _parsed(otherChargesCtrl);

    final total = expenseAmount +
        interest +
        lateFee +
        gst +
        otherCharges;

    totalPaidCtrl.text = total.toStringAsFixed(2);
  }

  Future<bool> submit() async {
    _errorMessage = null;

    if (!formKey.currentState!.validate()) return false;

    if (_selectedBank == null) {
      _errorMessage = 'Please select a payment bank';
      notifyListeners();
      return false;
    }

    final cycle = currentBillingCycle;
    if (cycle == null) {
      _errorMessage = 'No active billing cycle found';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final payment = CreditPaymentModel(
        id: cycle.billingCycleId,
        billingCycleId: cycle.billingCycleId,
        bankId: _selectedBank!.id,
        bankName: _selectedBank!.bankName,
        expenseAmount: _parsed(expenseAmountCtrl),
        interest: _parsed(interestCtrl),
        lateFee: _parsed(lateFeeCtrl),
        gst: _parsed(gstCtrl),
        otherCharges: _parsed(otherChargesCtrl),
        totalPaid: _parsed(totalPaidCtrl),
        paymentDate: _paymentDate,
        createdAt: DateTime.now(),
        expenseId: '',
      );

      // 1. Log it as a normal expense entry (you'll fill in the datasource
      //    implementation later).
      String expenseId = await _expenseRepository.addCreditCardPaymentExpense(
        payment: payment,
        card: creditCard,
        billingCycle: cycle,
      );

      final updatedPayment = payment.copyWith(expenseId: expenseId);

      // 2. Record the payment against the credit card / billing cycle.
      final success = await _creditRepository.payCreditCard(
        payment: updatedPayment,
        creditCardId: creditCard.creditCardId,
        billingCycleId: cycle.billingCycleId,
      );

      if (!success) {
        _errorMessage = 'Payment could not be completed';
        return false;
      }

      // Refresh so currentBillingCycle / expense list reflect the payment.
      await fetchCreditCardDetails(creditCard.creditCardId);

      return true;
    } catch (e) {
      _errorMessage = 'Payment failed: $e';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  double _parsed(TextEditingController c) => double.tryParse(c.text) ?? 0;

  @override
  void dispose() {
    expenseAmountCtrl.dispose();
    interestCtrl.dispose();
    lateFeeCtrl.dispose();
    gstCtrl.dispose();
    otherChargesCtrl.dispose();
    totalPaidCtrl.dispose();

    super.dispose();
  }
}

import 'package:expence_app/features/creditCardManagement/data/model/billing_cycle_model.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card_expense_item_model.dart';
import 'package:expence_app/features/creditCardManagement/domain/repository/credit_repo.dart';
import 'package:expence_app/features/expense/domain/repository/expense_repository.dart';
import 'package:flutter/cupertino.dart';

import '../../../bank/data/model/bank_model.dart';
import '../../../bank/domain/repository/bank_repository.dart';
import '../../data/model/credit_payment.dart';

/// Whether a charge field (interest / GST / other charges) is being
/// entered as a flat amount or as a percentage of the expense amount.
enum AmountInputMode { amount, percentage }

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

    // Expense amount is the base for percentage-mode fields, so it needs
    // its own handler that recalculates them before totalling.
    expenseAmountCtrl.addListener(_onExpenseAmountChanged);
    interestCtrl.addListener(updateTheTotalAmountIfOtherValueChange);
    lateFeeCtrl.addListener(updateTheTotalAmountIfOtherValueChange);
    gstCtrl.addListener(updateTheTotalAmountIfOtherValueChange);
    otherChargesCtrl.addListener(updateTheTotalAmountIfOtherValueChange);

    // Percentage inputs recompute their corresponding amount field.
    interestPercentCtrl.addListener(
          () => _recalcPercentField(_interestMode, interestPercentCtrl, interestCtrl),
    );
    gstPercentCtrl.addListener(
          () => _recalcPercentField(_gstMode, gstPercentCtrl, gstCtrl),
    );
    otherChargesPercentCtrl.addListener(
          () => _recalcPercentField(
        _otherChargesMode,
        otherChargesPercentCtrl,
        otherChargesCtrl,
      ),
    );
  }

  final formKey = GlobalKey<FormState>();
  final TextEditingController expenseAmountCtrl = TextEditingController();
  final TextEditingController interestCtrl = TextEditingController();
  final TextEditingController lateFeeCtrl = TextEditingController();
  final TextEditingController gstCtrl = TextEditingController();
  final TextEditingController otherChargesCtrl = TextEditingController();
  final TextEditingController totalPaidCtrl = TextEditingController();

  // ── Percentage-mode support ─────────────────────────────────────────
  final TextEditingController interestPercentCtrl =
  TextEditingController(text: '0');
  final TextEditingController gstPercentCtrl =
  TextEditingController(text: '0');
  final TextEditingController otherChargesPercentCtrl =
  TextEditingController(text: '0');

  AmountInputMode _interestMode = AmountInputMode.amount;
  AmountInputMode _gstMode = AmountInputMode.amount;
  AmountInputMode _otherChargesMode = AmountInputMode.amount;

  AmountInputMode get interestMode => _interestMode;
  AmountInputMode get gstMode => _gstMode;
  AmountInputMode get otherChargesMode => _otherChargesMode;

  void setInterestMode(AmountInputMode mode) =>
      _setMode(mode, () => _interestMode, (m) => _interestMode = m,
          interestPercentCtrl, interestCtrl);

  void setGstMode(AmountInputMode mode) =>
      _setMode(mode, () => _gstMode, (m) => _gstMode = m, gstPercentCtrl,
          gstCtrl);

  void setOtherChargesMode(AmountInputMode mode) => _setMode(
      mode,
          () => _otherChargesMode,
          (m) => _otherChargesMode = m,
      otherChargesPercentCtrl,
      otherChargesCtrl);

  void _setMode(
      AmountInputMode mode,
      AmountInputMode Function() currentMode,
      void Function(AmountInputMode) apply,
      TextEditingController percentCtrl,
      TextEditingController amountCtrl,
      ) {
    if (currentMode() == mode) return;

    if (mode == AmountInputMode.percentage) {
      // Switching TO percentage: back-derive a starting % from whatever
      // flat amount is currently entered, so the user doesn't lose data.
      final base = _parsed(expenseAmountCtrl);
      final amount = _parsed(amountCtrl);
      final percent = base > 0 ? (amount / base * 100) : 0.0;
      percentCtrl.text = percent.toStringAsFixed(2);
    }

    apply(mode);

    if (mode == AmountInputMode.percentage) {
      _recalcPercentFieldRaw(percentCtrl, amountCtrl);
    }

    notifyListeners();
  }

  void _onExpenseAmountChanged() {
    _recalcPercentField(_interestMode, interestPercentCtrl, interestCtrl);
    _recalcPercentField(_gstMode, gstPercentCtrl, gstCtrl);
    _recalcPercentField(
        _otherChargesMode, otherChargesPercentCtrl, otherChargesCtrl);
    updateTheTotalAmountIfOtherValueChange();
  }

  void _recalcPercentField(
      AmountInputMode mode,
      TextEditingController percentCtrl,
      TextEditingController amountCtrl,
      ) {
    if (mode != AmountInputMode.percentage) return;
    _recalcPercentFieldRaw(percentCtrl, amountCtrl);
  }

  void _recalcPercentFieldRaw(
      TextEditingController percentCtrl,
      TextEditingController amountCtrl,
      ) {
    final base = _parsed(expenseAmountCtrl);
    final percent = _parsed(percentCtrl);
    final amount = base * percent / 100;
    amountCtrl.text = amount.toStringAsFixed(2);
  }
  // ─────────────────────────────────────────────────────────────────────

  BankModel? _selectedBank;

  BankModel? get selectedBank => _selectedBank;

  DateTime _paymentDate = DateTime.now();

  DateTime get paymentDate => _paymentDate;

  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  // ── Screen-scoped payment target (passed in from the screen, not
  // resolved from "current" state) ────────────────────────────────────
  CreditCardModel? _paymentCreditCard;
  BillingCycleModel? _paymentBillingCycle;
  bool _isCurrentCycle = true;

  CreditCardModel get paymentCreditCard => _paymentCreditCard ?? _creditCard!;
  BillingCycleModel? get paymentBillingCycle => _paymentBillingCycle;
  bool get isCurrentCycle => _isCurrentCycle;

  double get highestCurrentMonth {
    if (_creditCardExpenseByBillingCycle.isEmpty) return 0.0;
    return _creditCardExpenseByBillingCycle
        .map((d) => d.amount)
        .reduce((a, b) => a > b ? a : b);
  }

  void paymentScreenFieldInit(
      CreditCardModel creditCard,
      BillingCycleModel billingCycle, {
        required BankModel bank,
        bool isCurrentCycle = true,
      }) {
    _paymentCreditCard = creditCard;
    _paymentBillingCycle = billingCycle;
    _isCurrentCycle = isCurrentCycle;

    expenseAmountCtrl.text = billingCycle.totalAmount.toStringAsFixed(2);
    interestCtrl.text = '0';
    lateFeeCtrl.text = '0';
    gstCtrl.text = '0';
    otherChargesCtrl.text = '0';

    interestPercentCtrl.text = '0';
    gstPercentCtrl.text = '0';
    otherChargesPercentCtrl.text = '0';
    _interestMode = AmountInputMode.amount;
    _gstMode = AmountInputMode.amount;
    _otherChargesMode = AmountInputMode.amount;

    _selectedBank = bank;
    totalPaidCtrl.text = billingCycle.totalAmount.toStringAsFixed(2);

    notifyListeners();
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

    final total = expenseAmount + interest + lateFee + gst + otherCharges;

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

    final card = _paymentCreditCard;
    final cycle = _paymentBillingCycle;
    if (card == null || cycle == null) {
      _errorMessage = 'No billing cycle found for this payment';
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
        interest: _parsed(interestCtrl), // always the resolved amount,
        lateFee: _parsed(lateFeeCtrl),   // whether it came from % or ₹ entry
        gst: _parsed(gstCtrl),
        otherCharges: _parsed(otherChargesCtrl),
        totalPaid: _parsed(totalPaidCtrl),
        paymentDate: _paymentDate,
        createdAt: DateTime.now(),
        expenseId: '',
      );

      String expenseId = await _expenseRepository.addCreditCardPaymentExpense(
        payment: payment,
        card: card,
        billingCycle: cycle,
      );

      final updatedPayment = payment.copyWith(expenseId: expenseId);

      final success = await _creditRepository.payCreditCard(
        payment: updatedPayment,
        creditCardId: card.creditCardId,
        billingCycleId: cycle.billingCycleId,
      );

      if (!success) {
        _errorMessage = 'Payment could not be completed';
        return false;
      }

      if (_creditCard != null) {
        await fetchCreditCardDetails(_creditCard!.creditCardId);
      }

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
    interestPercentCtrl.dispose();
    gstPercentCtrl.dispose();
    otherChargesPercentCtrl.dispose();

    super.dispose();
  }
}
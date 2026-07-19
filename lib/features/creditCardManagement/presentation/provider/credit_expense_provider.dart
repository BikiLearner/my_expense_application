import 'dart:async';

import 'package:expence_app/features/creditCardManagement/data/model/billing_cycle_model.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card_expense_item_model.dart';
import 'package:expence_app/shared/providers/auto_complete_key_provider.dart';
import 'package:expence_app/shared/providers/expense_type_selector_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/session_maganger.dart';
import '../../../../shared/dialogs/app_loader_dialog.dart';
import '../../../../shared/enums/expense_type.dart';
import '../../data/model/credit_card.dart';
import '../../domain/repository/credit_repo.dart';

class CreditExpenseProvider extends ChangeNotifier
    implements AutoCompleteProvider, ExpenseTypeProvider {
  List<CreditCardModel> _creditCards = [];

  List<CreditCardModel> get creditCards => _creditCards;

  CreditCardModel? _selectedCreditCard;

  CreditCardModel? get selectedCreditCard => _selectedCreditCard;
  BillingCycleModel? _selectedBillingCycleModel;

  BillingCycleModel? get selectedBillingCycleModel =>
      _selectedBillingCycleModel;

  final Map<String, BillingCycleModel> _currentBillingCyclePerCreditCard = {};
  final Map<String, StreamSubscription<BillingCycleModel?>>
  _billingCycleSubscriptions = {};

  DateTime get minimumSelectableDate =>
      _selectedBillingCycleModel?.startDate ?? DateTime.now();

  DateTime get maximumSelectableDate =>
      _selectedBillingCycleModel?.endDate ?? DateTime.now();

  bool isDateInCurrentBillingCycle(DateTime date) {
    final cycle = _selectedBillingCycleModel;
    if (cycle == null) return false;

    final day = DateTime(date.year, date.month, date.day);

    return !day.isBefore(cycle.startDate) && !day.isAfter(cycle.endDate);
  }

  @override
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  int _autoCompleteKey = 0;

  @override
  // The autocomplete key override as implemented AutoCompleteProvider
  int get autoCompleteKey => _autoCompleteKey;

  //selected type
  ExpenseType _selectedType = ExpenseType.luxury;

  @override
  ExpenseType get selectedType => _selectedType;

  DateTime _selectedDate = DateTime.now();

  DateTime get selectedDate => _selectedDate;

  List<CreditExpenseItem> _cachedExpenses = [];

  List<CreditExpenseItem> get cachedExpenses => _cachedExpenses;

  final CreditRepository _repository;

  StreamSubscription<List<CreditExpenseItem>>? _expenseSubscription;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  double get totalExpense {
    return _selectedBillingCycleModel?.totalAmount ?? 0;
  }

  CreditExpenseProvider({required CreditRepository repository})
    : _repository = repository {
    _init();
  }



  void setLoading() {
    _isLoading = !_isLoading;
    notifyListeners();
  }

  void setSelectedCreditCard(CreditCardModel creditCard) {
    _selectedCreditCard = creditCard;
    _selectedBillingCycleModel =
        _currentBillingCyclePerCreditCard[creditCard.creditCardId];
    _listenToExpenses();

    notifyListeners();
  }

  void setSelectedDate(DateTime picked) {
    _selectedDate = picked;
    notifyListeners();
  }

  Future<void> addCreditExpense(BuildContext context) async {
    debugPrint("Started expense process");
    AppLoader.show(context, message: 'Saving expense...');

    final user = SessionManager.instance.user;
    if (user == null) {
      AppLoader.hide();
      return;
    }

    debugPrint("Started expense process 2");
    final title = titleController.text.trim();
    final amount = double.tryParse(
      amountController.text.replaceAll(',', '').trim(),
    );
    debugPrint("Started expense process 3");
    final desc = descriptionController.text.trim();

    if (title.isEmpty || amount == null || amount <= 0) {
      AppLoader.hide();
      return;
    }
    debugPrint("Started expense process 4");

    if (_selectedCreditCard == null) {
      throw Exception('Please select a credit card.');
    }
    debugPrint("Started expense process 5");

    try {
      await _repository.addCreditExpense(
        card: _selectedCreditCard!,
        title: title,
        amount: amount,
        description: desc,
        expenseTypeName: _selectedType.name,
        purchaseDate: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          DateTime.now().hour,
          DateTime.now().minute,
          DateTime.now().second,
        ),
      );

      clearForm();

      if (kDebugMode) {
        print("⚡ Expense added instantly for ");
      }
    } catch (e) {
      debugPrint("❌ Add expense failed: $e");
    } finally {
      AppLoader.hide();
    }
  }

  void clearForm() {
    titleController.clear();
    amountController.clear();
    descriptionController.clear();
    _autoCompleteKey++; // Force rebuild
    _selectedType = ExpenseType.luxury; // Reset to default
    notifyListeners();
  }

  Future<void> addCreditCard({
    required String cardName,
    required String bankName,
    required double creditLimit,
    required int statementDay,
    required int dueDay,
    required BuildContext context,
  }) async {
    setLoading();
    await _repository.createCreditCard(
      cardName: cardName,
      bankName: bankName,
      creditLimit: creditLimit,
      statementDay: statementDay,
      dueDay: dueDay,
    );
    await fetchCreditCards();
    setLoading();
    notifyListeners();
  }

  Future<void> fetchCreditCards() async {
    _isLoading = true;
    notifyListeners();

    try {
      _creditCards = await _repository.fetchCreditCards();

      if (_creditCards.isNotEmpty) {
        _selectedCreditCard = _creditCards.first;
      }

      await _listenToBillingCycles();

      if (_selectedCreditCard != null) {
        _selectedBillingCycleModel =
            _currentBillingCyclePerCreditCard[_selectedCreditCard!
                .creditCardId];
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to fetch credit cards: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _listenToExpenses() async {
    await _expenseSubscription?.cancel();

    debugPrint("Called listen to expense");

    final card = _selectedCreditCard;
    final billingCycle = _selectedBillingCycleModel;

    if (card == null || billingCycle == null) {
      _cachedExpenses = [];
      notifyListeners();
      return;
    }

    _expenseSubscription = _repository
        .watchCreditExpensesByDate(
          creditCardId: card.creditCardId,
          billingCycleId: billingCycle.billingCycleId, selectedDate: selectedDate,
        )
        .listen(
          (expenses) {
            _cachedExpenses = expenses;
            notifyListeners();
          },
          onError: (e, stackTrace) {
            debugPrint('❌ Failed to listen credit expenses: $e');
            debugPrintStack(stackTrace: stackTrace);
          },
        );
  }

  Future<void> _listenToBillingCycles() async {
    // Cancel previous listeners
    for (final subscription in _billingCycleSubscriptions.values) {
      await subscription.cancel();
    }

    _billingCycleSubscriptions.clear();
    _currentBillingCyclePerCreditCard.clear();

    for (final card in _creditCards) {
      // Skip if no current billing cycle yet
      if (card.currentBillingCycleId == null ||
          card.currentBillingCycleId!.isEmpty) {
        continue;
      }

      final subscription = _repository
          .watchBillingCycle(
            creditCardId: card.creditCardId,
            billingCycleId: card.currentBillingCycleId!,
          )
          .listen((billingCycle) {
            if (billingCycle == null) return;

            _currentBillingCyclePerCreditCard[card.creditCardId] = billingCycle;

            if (_selectedCreditCard?.creditCardId == card.creditCardId) {
              _selectedBillingCycleModel = billingCycle;
              _listenToExpenses();
            }

            notifyListeners();
          });

      _billingCycleSubscriptions[card.creditCardId] = subscription;
    }
  }


  Future<void> editExpense({
    required BuildContext context,
    required String docId,
  }) async {
    AppLoader.show(context, message: 'Updating expense...');

    try {
      final title = titleController.text.trim();
      final amount = double.tryParse(
        amountController.text.replaceAll(',', '').trim(),
      );
      final description = descriptionController.text.trim();

      if (title.isEmpty || amount == null || amount <= 0) {
        throw Exception('Invalid expense details.');
      }

      if (_selectedCreditCard == null) {
        throw Exception('Please select a credit card.');
      }

      if (_selectedBillingCycleModel == null) {
        throw Exception('No billing cycle selected.');
      }

      await _repository.editCreditExpense(
        creditCardId: _selectedCreditCard!.creditCardId,
        billingCycleId: _selectedBillingCycleModel!.billingCycleId,
        expenseId: docId,
        title: title,
        amount: amount,
        description: description,
        expenseTypeName: _selectedType.name,
        purchaseDate: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          DateTime.now().hour,
          DateTime.now().minute,
          DateTime.now().second,
        ),
      );

      clearForm();
    } catch (e, stackTrace) {
      debugPrint('❌ Edit expense failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      AppLoader.hide();
    }
  }

  Future<void> deleteExpense({
    required BuildContext context,
    required String expenseId,
  }) async {
    AppLoader.show(context, message: 'Deleting expense...');

    try {
      if (_selectedCreditCard == null) {
        throw Exception('Please select a credit card.');
      }

      if (_selectedBillingCycleModel == null) {
        throw Exception('No billing cycle selected.');
      }

      await _repository.deleteCreditExpense(
        creditCardId: _selectedCreditCard!.creditCardId,
        billingCycleId: _selectedBillingCycleModel!.billingCycleId,
        expenseId: expenseId,
      );

      if (kDebugMode) {
        print('🗑️ Credit expense deleted successfully');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Delete expense failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      AppLoader.hide();
    }
  }

  Future<void> _init() async {
    await fetchCreditCards();
  }

  @override
  void setExpenseType(ExpenseType type) {
    if (_selectedType == type) return;
    _selectedType = type;
    notifyListeners();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    _expenseSubscription?.cancel();
    for (final sub in _billingCycleSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }
}

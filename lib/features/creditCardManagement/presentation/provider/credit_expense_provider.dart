import 'dart:async';

import 'package:expence_app/features/creditCardManagement/data/model/credit_card_expense_item_model.dart';
import 'package:expence_app/shared/providers/auto_complete_key_provider.dart';
import 'package:expence_app/shared/providers/expense_type_selector_provider.dart';
import 'package:flutter/cupertino.dart';

import '../../../../shared/enums/expense_type.dart';
import '../../data/model/credit_card.dart';
import '../../domain/repository/credit_repo.dart';

class CreditExpenseProvider extends ChangeNotifier implements AutoCompleteProvider,ExpenseTypeProvider{

  CreditCardModel? _selectedCreditCard;

  CreditCardModel? get selectedCreditCard => _selectedCreditCard;

  @override
  TextEditingController get titleController => throw UnimplementedError();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();


  String get currentBillingCycleId {
    if (_selectedCreditCard == null) {
      throw StateError('No credit card selected');
    }

    return _selectedCreditCard!.billingCycle.currentBillingCycleId;
  }

  @override
  // The autocomplete key override as implemented AutoCompleteProvider
  int get autoCompleteKey => throw UnimplementedError();

  //selected type
  ExpenseType _selectedType = ExpenseType.luxury;
  ExpenseType get selectedType => _selectedType;


  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;


  List<CreditExpenseItem> _cachedExpenses = [];

  List<CreditExpenseItem> get cachedExpenses => _cachedExpenses;

  final CreditRepository _repository;

  StreamSubscription<List<CreditExpenseItem>>? _expenseSubscription;

  bool _isLoading = false;
  bool get isLoading => _isLoading;



  CreditExpenseProvider({
    required CreditRepository repository,
  }) : _repository = repository {
    _init();
  }



  Future<void> _init() async {
    _initStream();
  }

  void _initStream() {
    _subscribeToExpenses();
  }

  void setSelectedCreditCard(CreditCardModel card) {
    if (_selectedCreditCard?.id == card.id) return;

    _selectedCreditCard = card;
    _subscribeToExpenses();
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    if (_selectedDate == date) return;

    _selectedDate = date;
    _subscribeToExpenses();
    notifyListeners();
  }

  @override
  void setExpenseType(ExpenseType type) {
    if (_selectedType == type) return;
    _selectedType = type;
    notifyListeners();
  }

  void _subscribeToExpenses() {
    if (_selectedCreditCard == null) {
      _cachedExpenses = [];
      notifyListeners();
      return;
    }

    _expenseSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

    _expenseSubscription = _repository.watchCreditExpenses(
      creditCardId: _selectedCreditCard!.id,
      billingCycleId: currentBillingCycleId,
      selectedDate: _selectedDate,
    ).listen(
          (items) {
        _cachedExpenses = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _cachedExpenses = [];
        _isLoading = false;
        notifyListeners();
      },
    );
  }
  Future<void> refresh() async {
    _subscribeToExpenses();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    _expenseSubscription?.cancel();
    super.dispose();
  }

}
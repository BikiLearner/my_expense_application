import 'dart:async';

import 'package:expence_app/features/creditCardManagement/data/model/credit_card_expense_item_model.dart';
import 'package:expence_app/shared/providers/auto_complete_key_provider.dart';
import 'package:expence_app/shared/providers/expense_type_selector_provider.dart';
import 'package:flutter/cupertino.dart';

import '../../../../shared/enums/expense_type.dart';
import '../../data/model/credit_card.dart';
import '../../domain/repository/credit_repo.dart';

class CreditExpenseProvider extends ChangeNotifier
    implements AutoCompleteProvider, ExpenseTypeProvider {


  List<CreditCardModel> _creditCards = [];
  List<CreditCardModel> get creditCards => _creditCards;


  CreditCardModel? _selectedCreditCard;

  CreditCardModel? get selectedCreditCard => _selectedCreditCard;

  @override
  TextEditingController get titleController => throw UnimplementedError();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();


  @override
  // The autocomplete key override as implemented AutoCompleteProvider
  int get autoCompleteKey => throw UnimplementedError();

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

  CreditExpenseProvider({required CreditRepository repository})
    : _repository = repository {
    _init();
  }

  void setLoading(){
    _isLoading=!_isLoading;
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
    } catch (e, stackTrace) {

      debugPrint('❌ Failed to fetch credit cards: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
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
    super.dispose();
  }
}

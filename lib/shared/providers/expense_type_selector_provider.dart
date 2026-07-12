import 'package:flutter/cupertino.dart';

import '../enums/expense_type.dart';

abstract class ExpenseTypeProvider implements Listenable {
  ExpenseType get selectedType;
  void setExpenseType(ExpenseType type);
}
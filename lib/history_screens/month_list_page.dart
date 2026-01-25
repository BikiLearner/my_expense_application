import 'package:expence_app/expense_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'monthly_expense_list.dart';

class MonthlyExpensePageHolidingList extends StatelessWidget {
  final Map<String, List<ExpenseDay>> grouped;

  const MonthlyExpensePageHolidingList({super.key, required this.grouped});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 👈 page background
      appBar: AppBar(
        backgroundColor: Colors.black, // 👈 app bar background
        elevation: 0,
        title: const Text(
          'Monthly Expenses',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: MonthlyExpenseList(grouped: grouped),
    );
  }
}

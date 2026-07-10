import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../expense/data/model/expense_model.dart';
import '../../../expense/presentation/provider/expence_provider.dart';
import 'monthly_expense_list.dart';

class MonthlyExpensePageHolidingList extends StatelessWidget {
  const MonthlyExpensePageHolidingList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Monthly Expenses',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: FutureBuilder<List<ExpenseDay>>(
        future: provider.getAllExpenseDays(), // 🔥 fetch EVERYTHING
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No expenses found',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final days = snapshot.data!;

          // 🔥 Group ALL years by month (yyyy-MM)
          final grouped = _groupByMonthAllYears(days);

          return MonthlyExpenseList(grouped: grouped);
        },
      ),
    );
  }

  /// 🔥 Groups ALL months across ALL years
  Map<String, List<ExpenseDay>> _groupByMonthAllYears(
      List<ExpenseDay> days,
      ) {
    final Map<String, List<ExpenseDay>> map = {};

    for (final d in days) {
      final monthKey = d.dateId.substring(0, 7); // yyyy-MM
      map.putIfAbsent(monthKey, () => []).add(d);
    }

    // 🔥 Sort months latest → oldest
    final sortedKeys = map.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return {
      for (final k in sortedKeys) k: map[k]!,
    };
  }
}

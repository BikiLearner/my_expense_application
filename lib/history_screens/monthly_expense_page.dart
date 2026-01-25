import 'package:expence_app/reusable%20widgets/day_expense.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense_items.dart';
import '../providers/expence_provider.dart';
import '../providers/month_expense_provider.dart';

class MonthlyExpensePage extends StatefulWidget {
  final String label;
  final String monthKey; // yyyy-MM

  const MonthlyExpensePage({
    super.key,
    required this.label,
    required this.monthKey,
  });

  @override
  State<MonthlyExpensePage> createState() => _MonthlyExpensePageState();
}

class _MonthlyExpensePageState extends State<MonthlyExpensePage> {
  @override
  void initState() {
    super.initState();

    // 🔥 IMPORTANT: set month only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MonthExpensesProvider>().setMonth(widget.monthKey);
    });
  }

  @override
  void dispose() {
    // Optional: clear when leaving screen
    context.read<MonthExpensesProvider>().clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // 👈 back button color
        ),
        backgroundColor: const Color(0xFF0F1115),
        title: Text(widget.label, style: TextStyle(color: Colors.white)),
      ),

      // 🔥 Selector-based UI
      body: Selector<MonthExpensesProvider, bool>(
        selector: (_, p) => p.isLoading,
        builder: (context, isLoading, _) {
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
            );
          }

          return Selector<MonthExpensesProvider, List<String>>(
            selector: (_, p) => p.allDates,
            builder: (context, dates, __) {
              if (dates.isEmpty) {
                return const Center(
                  child: Text(
                    'No expenses for this month',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: dates.map((dateId) {
                  return Selector<MonthExpensesProvider, List<ExpenseItem>>(
                    selector: (_, p) => p.getExpensesForDate(dateId),
                    builder: (context, items, ___) {
                      return DayCard(dateId: dateId, items: items);
                    },
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}

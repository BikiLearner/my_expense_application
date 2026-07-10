import 'package:expence_app/shared/widgets/simple_grand_total_form_month.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/month_expense_provider.dart';
import '../../../../shared/widgets/day_expense.dart';
import '../../../expense/data/model/expense_items.dart';

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

    // 🔥 Set month once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MonthExpensesProvider>().setMonth(widget.monthKey);
    });
  }

  @override
  void dispose() {
    context.read<MonthExpensesProvider>().clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1115),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.label, style: const TextStyle(color: Colors.white)),
      ),
      body: Selector<MonthExpensesProvider, bool>(
        selector: (_, p) => p.isLoading,
        builder: (context, isLoading, _) {
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
            );
          }

          return Column(
            children: [
              /// 🔥 MONTH SUMMARY (STATIC – NOT SCROLLING)
              SimpleMonthSummaryBanner(
                monthKey: widget.monthKey,
              ),

              /// 🔹 DAY LIST (SCROLLABLE)
              Expanded(
                child: Selector<MonthExpensesProvider, List<String>>(
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

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: dates.length,
                      itemBuilder: (context, index) {
                        final dateId = dates[index];

                        return Selector<MonthExpensesProvider,
                            List<ExpenseItem>>(
                          selector: (_, p) => p.getExpensesForDate(dateId),
                          builder: (context, items, ___) {
                            return DayCard(
                              dateId: dateId,
                              items: items,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
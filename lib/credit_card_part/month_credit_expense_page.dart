import 'package:expence_app/history_screens/simple_grand_total_form_month.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense_items.dart';
import '../providers/month_expense_provider.dart';
import '../reusable widgets/day_expense.dart';
// Update this path as needed

class MonthCreditExpensePage extends StatefulWidget {
  final String label;
  final String monthKey; // yyyy-MM

  const MonthCreditExpensePage({
    super.key,
    required this.label,
    required this.monthKey,
  });

  @override
  State<MonthCreditExpensePage> createState() => _MonthCreditExpensePage();
}

class _MonthCreditExpensePage extends State<MonthCreditExpensePage> {
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
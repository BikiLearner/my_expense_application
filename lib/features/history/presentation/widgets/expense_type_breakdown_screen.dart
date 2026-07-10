import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/enums/expense_type.dart';
import '../provider/month_expense_provider.dart';
import '../../../../shared/widgets/day_expense.dart';
import '../../../expense/data/model/expense_items.dart';

class ExpenseTypeBreakdownScreen extends StatelessWidget {
  final ExpenseType type;
  final String monthKey; // yyyy-MM

  const ExpenseTypeBreakdownScreen({
    super.key,
    required this.type,
    required this.monthKey,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure correct month is loaded (no rebuild)
    final provider = context.read<MonthExpensesProvider>();
    if (provider.currentMonth != monthKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.setMonth(monthKey);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          '${type.label} • $monthKey',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Selector<MonthExpensesProvider, bool>(
        selector: (_, p) => p.isLoading,
        builder: (context, isLoading, _) {
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
            );
          }

          return _ExpenseTypeBody(type: type);
        },
      ),
    );
  }
}

class _ExpenseTypeBody extends StatelessWidget {
  final ExpenseType type;

  const _ExpenseTypeBody({required this.type});

  @override
  Widget build(BuildContext context) {
    return Selector<
      MonthExpensesProvider,
      ({Map<String, List<ExpenseItem>> grouped, double total})
    >(
      selector: (_, p) => (
        grouped: p.getExpensesForType(type),
        total: p.getMonthTotalForType(type),
      ),
      shouldRebuild: (prev, next) =>
          prev.total != next.total || !mapEquals(prev.grouped, next.grouped),
      builder: (context, data, _) {
        if (data.grouped.isEmpty) {
          return const Center(
            child: Text(
              'No expenses found',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // Sort dates (latest first)
        final sortedEntries = data.grouped.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));

        return Column(
          children: [
            /// 🔹 Total Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    type.color.withOpacity(0.8),
                    type.color.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(color: Colors.white70)),
                  Text(
                    '₹${data.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// 🔹 Day-wise breakdown using DayCard
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: sortedEntries.length,
                itemBuilder: (context, index) {
                  final entry = sortedEntries[index];
                  final dateId = entry.key;
                  final items = entry.value;

                  return DayCard(dateId: dateId, items: items);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../enums/expense_type.dart';
import '../providers/expence_provider.dart';
import '../expense_model.dart';
import 'day_expense_tile.dart';

class ExpenseTypeBreakdownScreen extends StatelessWidget {
  final ExpenseType type;

  const ExpenseTypeBreakdownScreen({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          '${type.label} Expenses',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder<Map<String, List<ExpenseDay>>>(
        future: context
            .read<ExpenseProvider>()
            .getExpensesGroupedByMonthForType(type),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
            );
          }

          final grouped = snapshot.data!;
          final total = grouped.values
              .expand((e) => e)
              .fold(0.0, (s, d) => s + d.total);

          if (grouped.isEmpty) {
            return const Center(
              child: Text(
                'No expenses found',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              // 🔹 Total banner
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
                    const Text(
                      'Total',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Monthly breakdown
              Expanded(
                child: ListView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: grouped.entries
                      .map(
                        (e) => _MonthTile(
                      monthKey: e.key,
                      days: e.value,
                    ),
                  )
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
class _MonthTile extends StatelessWidget {
  final String monthKey;
  final List<ExpenseDay> days;

  const _MonthTile({
    required this.monthKey,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final label =
    DateFormat('MMMM yyyy').format(DateTime.parse('$monthKey-01'));
    final total = days.fold(0.0, (s, d) => s + d.total);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: Text(
          '₹${total.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Color(0xFF64FFDA),
            fontWeight: FontWeight.bold,
          ),
        ),
        children: days
            .map(
              (d) => DayExpenseTile(day: d),
        )
            .toList(),
      ),
    );
  }
}

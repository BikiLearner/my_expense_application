import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../expense_home/models/expense_model.dart';
import 'day_expense_tile.dart';
import 'monthly_expense_page.dart';

class MonthlyExpenseList extends StatelessWidget {
  final Map<String, List<ExpenseDay>> grouped;

  const MonthlyExpenseList({super.key, required this.grouped});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: grouped.entries
          .map((e) => MonthTile(monthKey: e.key, days: e.value))
          .toList(),
    );
  }
}

class MonthTile extends StatelessWidget {
  final String monthKey;
  final List<ExpenseDay> days;

  const MonthTile({super.key, required this.monthKey, required this.days});

  @override
  Widget build(BuildContext context) {
    final label = DateFormat(
      'MMMM yyyy',
    ).format(DateTime.parse("$monthKey-01"));
    final total = days.fold(0.0, (s, d) => s + d.total);
    final daysCount = days.length;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MonthlyExpensePage(label: label, monthKey: monthKey),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF64FFDA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_month,
                color: Color(0xFF64FFDA),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$daysCount day${daysCount == 1 ? '' : 's'}",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF64FFDA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF64FFDA).withOpacity(0.3),
                ),
              ),
              child: Text(
                '₹${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF64FFDA),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

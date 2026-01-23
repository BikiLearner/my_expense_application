import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense_items.dart';
import 'expense_tiles_new.dart';

class DayCard extends StatelessWidget {
  final String dateId;
  final List<ExpenseItem> items; // yyyy-MM-dd

  const DayCard({
    super.key,
    required this.dateId, required this.items

  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(dateId);
    final dayTotal = items.fold<double>(
      0,
          (sum, d) => sum + d.amount.toDouble()
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171A21),
        borderRadius: BorderRadius.circular(18)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER (unchanged)
          _header(
            date: date,
            total: dayTotal
          ),

          const SizedBox(height: 12),

          Column(
            children: items.map((d) {
              return ExpenseItemTile(
                expenseItem: d, toShow: true,
              );
            }).toList()
          )

        ]
      )
    );
  }

  // 🔹 Extracted header to avoid duplication
  Widget _header({required DateTime date, required double total}) {
    return Row(
      children: [
        Text(
          DateFormat('dd EEE').format(date),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white
          )
        ),
        const Spacer(),
        Text(
          "₹${total.toStringAsFixed(0)}",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold
              ,
              color: Colors.white
          )
        )
      ]
    );
  }
}

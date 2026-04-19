import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../detail_screen.dart';
import '../expense_home/models/expense_model.dart';

class DayExpenseTile extends StatelessWidget {
  final ExpenseDay day;

  const DayExpenseTile({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(day.dateId);
    final isToday =
        DateFormat('yyyy-MM-dd').format(DateTime.now()) == day.dateId;
    final dayOfWeek = DateFormat('EEE').format(date); // Mon, Tue, etc.
    final dayOfMonth = DateFormat('dd').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DateDetailScreen(dateId: day.dateId, date: date),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isToday
                  ? const Color(0xFF64FFDA).withOpacity(0.05)
                  : const Color(0xFF252525),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday
                    ? const Color(0xFF64FFDA)
                    : Colors.white.withOpacity(0.05),
                width: isToday ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Date Circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF64FFDA).withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: isToday
                        ? Border.all(
                            color: const Color(0xFF64FFDA).withOpacity(0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayOfMonth,
                        style: TextStyle(
                          color: isToday
                              ? const Color(0xFF64FFDA)
                              : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayOfWeek,
                        style: TextStyle(
                          color: isToday
                              ? const Color(0xFF64FFDA)
                              : Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Today Badge (if applicable)
                if (isToday) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64FFDA).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "TODAY",
                      style: TextStyle(
                        color: Color(0xFF64FFDA),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${day.total.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isToday ? const Color(0xFF64FFDA) : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "View details",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class NoExpenseForMonth extends StatelessWidget {
  final String month;
  final String year;

  const NoExpenseForMonth({required this.month, required this.year});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😢', style: TextStyle(fontSize: 72)),

          const SizedBox(height: 16),

          Text(
            'No expenses for $month',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'No expense records found for $month $year',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

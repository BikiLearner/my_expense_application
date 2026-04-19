import 'package:expence_app/enums/expense_type.dart';
import 'package:expence_app/expense_home/models/expense_items.dart';
import 'package:expence_app/providers/bank_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'delete_expense_dialog.dart';
import 'edit_expense_dialog.dart';

class ExpenseItemTile extends StatelessWidget {
  final ExpenseItem expenseItem;
  final bool toShow;

  const ExpenseItemTile({
    super.key,
    required this.expenseItem,
    required this.toShow,
  });

  @override
  Widget build(BuildContext context) {
    final ExpenseType type = expenseItem.type;
    final String txn = context.read<BankProvider>().getTransactionBankName(expenseItem.transactionType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F232C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: type.color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // ICON
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: type.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(type.icon, color: type.color),
          ),
          const SizedBox(width: 12),

          // TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expenseItem.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white, 
                  ),
                ),
                if ((expenseItem.description ?? '').toString().isNotEmpty &&
                    toShow)
                  Text(
                    expenseItem.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9AA0A6),
                    ),
                  ),
                if (toShow)
                  Text(
                  txn,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9AA0A6),
                    ),
                  ),
              ],
            ),
          ),

          // AMOUNT
          Text(
            "₹${expenseItem.amount}",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            color: Colors.orangeAccent,
            onPressed: () => showDialog(
              context: context,
              builder: (_) => EditExpenseDialog(expense: expenseItem),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.redAccent,
            onPressed: () => showDialog(
              context: context,
              builder: (_) => DeleteExpenseDialog(expense: expenseItem),
            ),
          ),
        ],
      ),
    );
  }
}

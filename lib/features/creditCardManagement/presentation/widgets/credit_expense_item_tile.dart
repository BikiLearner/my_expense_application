import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../shared/enums/expense_type.dart';
import '../../data/model/credit_card_expense_item_model.dart';
import 'delete_credit_expense_dialog.dart';
import 'edit_credit_expense_dialog.dart';


class CreditExpenseItemTile extends StatelessWidget {
  final CreditExpenseItem expenseItem;
  final bool toShow;

  const CreditExpenseItemTile({
    super.key,
    required this.expenseItem,
    required this.toShow,
  });

  @override
  Widget build(BuildContext context) {
    final ExpenseType type = expenseItem.type;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.cardBg,
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
                    color: AppColor.textPrimary,
                  ),
                ),
                if (expenseItem.description.isNotEmpty && toShow)
                  Text(
                    expenseItem.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColor.textGrey,
                    ),
                  ),
                if (toShow)
                  Text(
                    DateFormat('dd MMM yyyy').format(expenseItem.purchaseDate),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColor.textGrey,
                    ),
                  ),
              ],
            ),
          ),

          // AMOUNT
          Text(
            "₹${expenseItem.amount.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),

          IconButton(
            icon: const Icon(Icons.edit_outlined),
            color: AppColor.paletteAmber,
            onPressed: () => showDialog(
              context: context,
              builder: (_) => EditCreditExpenseDialog(expense: expenseItem),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppColor.twRed,
            onPressed: () => showDialog(
              context: context,
              builder: (_) => DeleteCreditExpenseDialog(expense: expenseItem),
            ),
          ),
        ],
      ),
    );
  }
}
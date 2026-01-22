import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expence_app/enums/transaction_type_enum.dart';

import '../enums/expense_type.dart';

class ExpenseItem {
  final String id;
  final String dateId; // ✅ ADD THIS
  final String title;
  final double amount;
  final ExpenseType type;
  final String description;
  final DateTime createdAt;
  final TransactionTypeEnum transactionType;


  ExpenseItem({
    required this.id,
    required this.dateId,
    required this.title,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
    required this.transactionType,
  });

  factory ExpenseItem.fromFirestore(
      String id,
      Map<String, dynamic> data,
      String dateId, // pass from stream
      ) {
    return ExpenseItem(
      id: id,
      dateId: dateId,
      title: data['title'],
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] ?? '',
      type: ExpenseType.values.firstWhere(
            (e) => e.name == data['type'],
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      transactionType: TransactionTypeEnum.values.firstWhere(
            (e) => e.name == (data['transactionType'] ?? TransactionTypeEnum.cash.name),
      ),

    );
  }
}

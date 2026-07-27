import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/enums/expense_type.dart';

class CreditExpenseItem {
  final String id;
  final String title;
  final double amount;
  final int split;
  final ExpenseType type;
  final String description;
  final DateTime purchaseDate;
  final DateTime createdAt;

  CreditExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    this.split = 0,
    required this.type,
    required this.description,
    required this.purchaseDate,
    required this.createdAt,
  });

  /// Actual expense belonging to the user.
  ///
  /// amount = 150, split = 3  -> 50
  /// amount = 150, split = 0  -> 150
  double get personalAmount {
    if (split > 0) {
      return amount / split;
    }

    return amount;
  }

  factory CreditExpenseItem.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {
    return CreditExpenseItem(
      id: id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,

      // Old expenses without this field automatically become 0.
      split: (data['split'] as num?)?.toInt() ?? 0,

      type: ExpenseType.values.firstWhere(
            (e) => e.name == data['type'],
        orElse: () => ExpenseType.needed,
      ),
      description: data['description'] ?? '',
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'split': split,
      'type': type.name,
      'description': description,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CreditExpenseItem copyWith({
    String? title,
    double? amount,
    int? split,
    ExpenseType? type,
    String? description,
    DateTime? purchaseDate,
    DateTime? createdAt,
  }) {
    return CreditExpenseItem(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      split: split ?? this.split,
      type: type ?? this.type,
      description: description ?? this.description,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
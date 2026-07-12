import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/enums/expense_type.dart';

class CreditExpenseItem {
  final String id;
  final String title;
  final double amount;
  final ExpenseType type;
  final String description;
  final DateTime purchaseDate;

  final bool isPaid;
  final DateTime createdAt;

  CreditExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.description,
    required this.purchaseDate,

    required this.isPaid,

    required this.createdAt,
  });

  factory CreditExpenseItem.fromFirestore(String id, Map<String, dynamic> data) {
    return CreditExpenseItem(
      id: id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      type: ExpenseType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ExpenseType.needed,
      ),
      description: data['description'] ?? '',
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),

      isPaid: data['isPaid'] ?? false,

      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'type': type.name,
      'description': description,
      'purchaseDate': Timestamp.fromDate(purchaseDate),

      'isPaid': isPaid,

      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'description': description,
      'purchaseDate': purchaseDate.toIso8601String(),
      'isPaid': isPaid,

      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CreditExpenseItem.fromJson(Map<String, dynamic> json) {
    return CreditExpenseItem(
      id: json['id'],
      title: json['title'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: ExpenseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ExpenseType.needed,
      ),
      description: json['description'] ?? '',
      purchaseDate: DateTime.parse(json['purchaseDate']),

      isPaid: json['isPaid'],

      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  CreditExpenseItem copyWith({
    String? title,
    double? amount,
    ExpenseType? type,
    String? description,
    DateTime? purchaseDate,
    String? dateId,
    String? creditCardId,
    String? creditCardName,
    String? billingCycleId,
    bool? isPaid,

    DateTime? createdAt,
  }) {
    return CreditExpenseItem(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      purchaseDate: purchaseDate ?? this.purchaseDate,

      isPaid: isPaid ?? this.isPaid,

      createdAt: createdAt ?? this.createdAt,
    );
  }
}

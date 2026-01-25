import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expence_app/enums/transaction_type_enum.dart';
import '../enums/expense_type.dart';

class ExpenseItem {
  final String id;
  final String dateId; // yyyy-MM-dd
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

  /// 🔥 Firestore → Model
  factory ExpenseItem.fromFirestore(
    String id,
    Map<String, dynamic> data,
    String dateId,
  ) {
    return ExpenseItem(
      id: id,
      dateId: dateId,
      title: data['title'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] ?? '',
      type: ExpenseType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ExpenseType.needed,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      transactionType: TransactionTypeEnum.values.firstWhere(
        (e) =>
            e.name ==
            (data['transactionType'] ?? TransactionTypeEnum.cash.name),
        orElse: () => TransactionTypeEnum.cash,
      ),
    );
  }

  /// 💾 Model → JSON (local persistence)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateId': dateId,
      'title': title,
      'amount': amount,
      'description': description,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'transactionType': transactionType.name,
    };
  }

  /// 💾 JSON → Model (restore cache)
  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      id: json['id'],
      dateId: json['dateId'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] ?? '',
      type: ExpenseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ExpenseType.needed,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      transactionType: TransactionTypeEnum.values.firstWhere(
        (e) => e.name == json['transactionType'],
        orElse: () => TransactionTypeEnum.cash,
      ),
    );
  }

  /// 🧠 Optional: immutable updates
  ExpenseItem copyWith({
    String? title,
    double? amount,
    ExpenseType? type,
    String? description,
    DateTime? createdAt,
    TransactionTypeEnum? transactionType,
  }) {
    return ExpenseItem(
      id: id,
      dateId: dateId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      transactionType: transactionType ?? this.transactionType,
    );
  }
}

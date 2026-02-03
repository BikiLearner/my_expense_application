import 'package:cloud_firestore/cloud_firestore.dart';

enum CreditType {
  borrow,
  lent,
}

enum CreditStatus {
  active,
  completed,
}

class BankCredit {
  final String id;
  final String title;
  final double amount;
  final CreditType type;
  final CreditStatus status;
  final String? bankId; // used only for lent
  final Timestamp createdAt;
  final Timestamp? completedAt;

  BankCredit({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.bankId,
  });

  factory BankCredit.fromFirestore(String id, Map<String, dynamic> data) {
    return BankCredit(
      id: id,
      title: data['title'],
      amount: (data['amount'] as num).toDouble(),
      type: data['type'] == 'lent' ? CreditType.lent : CreditType.borrow,
      status: data['status'] == 'completed'
          ? CreditStatus.completed
          : CreditStatus.active,
      bankId: data['bankId'],
      createdAt: data['createdAt'],
      completedAt: data['completedAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'type': type.name,
      'status': status.name,
      'bankId': bankId,
      'createdAt': createdAt,
      'completedAt': completedAt,
    };
  }

  bool get isBorrow => type == CreditType.borrow;
  bool get isLent => type == CreditType.lent;
  bool get isActive => status == CreditStatus.active;
}

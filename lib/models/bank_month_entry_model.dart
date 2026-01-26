import 'package:cloud_firestore/cloud_firestore.dart';

class BankMonthEntry {
  final String id;
  final double amount;
  final Timestamp createdAt;

  BankMonthEntry({
    required this.id,
    required this.amount,
    required this.createdAt,
  });

  factory BankMonthEntry.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {
    return BankMonthEntry(
      id: id,
      amount: (data['amount'] as num).toDouble(),
      createdAt: data['createdAt'],
    );
  }
}

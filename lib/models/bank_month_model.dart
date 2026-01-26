import 'package:cloud_firestore/cloud_firestore.dart';

class BankMonthModel {
  final String id; // yyyy-MM
  final double totalAdded;
  final double currentAmount;
  final Timestamp? updatedAt;

  BankMonthModel({
    required this.id,
    required this.totalAdded,
    required this.currentAmount,
    this.updatedAt,
  });

  factory BankMonthModel.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {
    return BankMonthModel(
      id: id,
      totalAdded: (data['totalAdded'] as num).toDouble(),
      currentAmount: (data['currentAmount'] as num).toDouble(),
      updatedAt: data['updatedAt'],
    );
  }
}

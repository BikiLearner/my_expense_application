import 'package:cloud_firestore/cloud_firestore.dart';

class BankMonthModel {
  final String id; // yyyy-MM

  /// 💰 Total money added in this month (including init / top-ups)
  final double totalAdded;

  /// 💵 Current available balance for this month
  final double currentAmount;

  /// 🔁 Closing balance of previous month carried forward
  final double surplusPreviousMonth;

  /// 📈 Income added specifically during this month
  final double incomeThisMonth;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  BankMonthModel({
    required this.id,
    required this.totalAdded,
    required this.currentAmount,
    required this.surplusPreviousMonth,
    required this.incomeThisMonth,
    this.createdAt,
    this.updatedAt,
  });

  /// 🔹 Firestore → Model
  factory BankMonthModel.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {
    return BankMonthModel(
      id: id,
      totalAdded: (data['totalAdded'] ?? 0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0).toDouble(),
      surplusPreviousMonth:
      (data['surplusPreviousMonth'] ?? 0).toDouble(),
      incomeThisMonth:
      (data['incomeThisMonth'] ?? 0).toDouble(),
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  /// 🔹 Safe fallback when month doc doesn’t exist yet
  factory BankMonthModel.empty(String id) {
    return BankMonthModel(
      id: id,
      totalAdded: 0,
      currentAmount: 0,
      surplusPreviousMonth: 0,
      incomeThisMonth: 0,
      createdAt: null,
      updatedAt: null,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class BankModel {
  final String id;
  final String bankName;
  final double totalAmountWhenAdded;
  final double currentAmount;
  final Timestamp addedDate;

  BankModel({
    required this.id,
    required this.bankName,
    required this.totalAmountWhenAdded,
    required this.currentAmount,
    required this.addedDate,
  });

  factory BankModel.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {
    return BankModel(
      id: id,
      bankName: data['bankName'],
      totalAmountWhenAdded:
      (data['totalAmountWhenAdded'] as num).toDouble(),
      currentAmount: (data['currentAmount'] as num).toDouble(),
      addedDate: data['addedDate'],
    );
  }
}

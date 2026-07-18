import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class BankModel {
  final String id;
  final String bankName;
  final Timestamp addedDate;

  BankModel({
    required this.id,
    required this.bankName,
    required this.addedDate,
  });

  factory BankModel.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {
    return BankModel(
      id: id,
      bankName: data['bankName'] as String,
      addedDate: data['addedDate'] as Timestamp,
    );
  }

  @override
  String toString() {
    return 'BankModel{id: $id, bankName: $bankName, addedDate: $addedDate}';
  }

}


final BankModel cashBank = BankModel(
  id: 'cash',
  bankName: 'Cash',
  addedDate: Timestamp.now(),
);

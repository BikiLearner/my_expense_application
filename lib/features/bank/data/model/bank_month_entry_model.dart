import 'package:cloud_firestore/cloud_firestore.dart';

class BankMonthEntry {
  final String id;
  final double amount;
  final String description;
  final Timestamp createdAt;
  final String? type; // 'transfer_in', 'transfer_out', or null for regular entries
  final String? targetBankId; // For transfer_out
  final String? sourceBankId; // For transfer_in

  BankMonthEntry({
    required this.id,
    required this.amount,
    required this.createdAt,
    required this.description,
    this.type,
    this.targetBankId,
    this.sourceBankId,
  });

  factory BankMonthEntry.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {
    return BankMonthEntry(
      id: id,
      amount: (data['amount'] as num).toDouble(),
      createdAt: data['createdAt'],
      description: data['description'] ?? 'Not Provided',
      type: data['type'], // Can be null, 'transfer_in', or 'transfer_out'
      targetBankId: data['targetBankId'],
      sourceBankId: data['sourceBankId'],
    );
  }

  bool get isTransfer => type == 'transfer_in' || type == 'transfer_out';
  bool get isTransferIn => type == 'transfer_in';
  bool get isTransferOut => type == 'transfer_out';
}
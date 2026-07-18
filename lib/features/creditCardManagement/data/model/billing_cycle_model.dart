import 'package:cloud_firestore/cloud_firestore.dart';

class BillingCycleModel {
  final String id;

  final DateTime startDate;
  final DateTime endDate;

  final String status;

  final double totalAmount;

  final DateTime createdAt;

  const BillingCycleModel({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.status, // active or complete
    required this.totalAmount,
    required this.createdAt,
  });

  factory BillingCycleModel.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {
    return BillingCycleModel(
      id: id,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
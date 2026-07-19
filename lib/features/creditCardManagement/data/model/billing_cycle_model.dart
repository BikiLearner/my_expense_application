import 'package:cloud_firestore/cloud_firestore.dart';

class BillingCycleModel {
  final String billingCycleId;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double totalAmount;
  final DateTime createdAt;

  const BillingCycleModel({
    required this.billingCycleId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
  });

  factory BillingCycleModel.fromFirestore(
      String billingCycleId,
      Map<String, dynamic> data,
      ) {
    return BillingCycleModel(
      billingCycleId: billingCycleId,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'billingCycleId':billingCycleId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates the billing cycle for the given expense date.
  static BillingCycleModel calculate({
    required int statementDay,
    required DateTime expenseDate,
  }) {
    late DateTime startDate;
    late DateTime endDate;

    if (expenseDate.day >= statementDay) {
      startDate = DateTime(
        expenseDate.year,
        expenseDate.month,
        statementDay,
      );

      endDate = DateTime(
        expenseDate.year,
        expenseDate.month + 1,
        statementDay,
      ).subtract(const Duration(days: 1));
    } else {
      startDate = DateTime(
        expenseDate.year,
        expenseDate.month - 1,
        statementDay,
      );

      endDate = DateTime(
        expenseDate.year,
        expenseDate.month,
        statementDay,
      ).subtract(const Duration(days: 1));
    }

    final billingCycleId =
        '${startDate.year}-'
        '${startDate.month.toString().padLeft(2, '0')}-'
        '${startDate.day.toString().padLeft(2, '0')}';

    return BillingCycleModel(
      billingCycleId: billingCycleId,
      startDate: startDate,
      endDate: endDate,
      status: 'active',
      totalAmount: 0,
      createdAt: DateTime.now(),
    );
  }
}
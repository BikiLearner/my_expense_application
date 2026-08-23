import 'package:cloud_firestore/cloud_firestore.dart';

class CreditPaymentModel {
  final String id;

  final String billingCycleId;
  final String bankId;
  final String bankName; // Bank i paid from
  final double expenseAmount;
  final double interest;
  final double lateFee;
  final double gst;
  final double otherCharges;
  final double totalPaid;
  final String expenseId; // for the expense that will be create in main screen
  final DateTime paymentDate;
  final DateTime createdAt;

  CreditPaymentModel({
    required this.id,

    required this.billingCycleId,
    required this.bankId,
    required this.bankName,
    required this.expenseAmount,
    required this.interest,
    required this.lateFee,
    required this.gst,
    required this.otherCharges,
    required this.totalPaid,
    required this.expenseId,
    required this.paymentDate,
    required this.createdAt,
  });

  factory CreditPaymentModel.fromFirestore(String id, Map<String, dynamic> data) {
    return CreditPaymentModel(
      id: id,

      billingCycleId: data['billingCycleId'] ?? '',
      bankId: data['bankId'] ?? '',
      bankName: data['bankName'] ?? '',
      expenseAmount: (data['expenseAmount'] as num?)?.toDouble() ?? 0.0,
      interest: (data['interest'] as num?)?.toDouble() ?? 0.0,
      lateFee: (data['lateFee'] as num?)?.toDouble() ?? 0.0,
      gst: (data['gst'] as num?)?.toDouble() ?? 0.0,
      otherCharges: (data['otherCharges'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (data['totalPaid'] as num?)?.toDouble() ?? 0.0,
      expenseId: data['expenseId'] ?? '',
      paymentDate: (data['paymentDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'billingCycleId': billingCycleId,
      'bankId': bankId,
      'bankName': bankName,
      'expenseAmount': expenseAmount,
      'interest': interest,
      'lateFee': lateFee,
      'gst': gst,
      'otherCharges': otherCharges,
      'totalPaid': totalPaid,
      'expenseId': expenseId,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'billingCycleId': billingCycleId,
      'bankId': bankId,
      'bankName': bankName,
      'expenseAmount': expenseAmount,
      'interest': interest,
      'lateFee': lateFee,
      'gst': gst,
      'otherCharges': otherCharges,
      'totalPaid': totalPaid,
      'expenseId': expenseId,
      'paymentDate': paymentDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CreditPaymentModel.fromJson(Map<String, dynamic> json) {
    return CreditPaymentModel(
      id: json['id'],

      billingCycleId: json['billingCycleId'],
      bankId: json['bankId'],
      bankName: json['bankName'],
      expenseAmount: (json['expenseAmount'] as num?)?.toDouble() ?? 0.0,
      interest: (json['interest'] as num?)?.toDouble() ?? 0.0,
      lateFee: (json['lateFee'] as num?)?.toDouble() ?? 0.0,
      gst: (json['gst'] as num?)?.toDouble() ?? 0.0,
      otherCharges: (json['otherCharges'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
      expenseId: json['expenseId'],
      paymentDate: DateTime.parse(json['paymentDate']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  CreditPaymentModel copyWith({
    String? id,
    String? creditCardId,
    String? creditCardName,
    String? billingCycleId,
    String? bankId,
    String? bankName,
    double? expenseAmount,
    double? interest,
    double? lateFee,
    double? gst,
    double? otherCharges,
    double? totalPaid,
    String? expenseId,
    DateTime? paymentDate,
    DateTime? createdAt,
  }) {
    return CreditPaymentModel(
      id: id ?? this.id,
      billingCycleId: billingCycleId ?? this.billingCycleId,
      bankId: bankId ?? this.bankId,
      bankName: bankName ?? this.bankName,
      expenseAmount: expenseAmount ?? this.expenseAmount,
      interest: interest ?? this.interest,
      lateFee: lateFee ?? this.lateFee,
      gst: gst ?? this.gst,
      otherCharges: otherCharges ?? this.otherCharges,
      totalPaid: totalPaid ?? this.totalPaid,
      expenseId: expenseId ?? this.expenseId,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

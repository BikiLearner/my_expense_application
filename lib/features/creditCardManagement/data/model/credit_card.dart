import 'package:cloud_firestore/cloud_firestore.dart';

import 'billing_cycle_model_for_ui.dart';

class CreditCardModel {
  final String creditCardId;
  final String cardName;
  final String bankName;
  final double creditLimit;
  final int statementDay; // 1-31
  final int dueDay;// 1-31
  final bool isActive;
  final DateTime createdAt;


  const CreditCardModel({
    required this.creditCardId,
    required this.cardName,
    required this.bankName,
    required this.creditLimit,
    required this.statementDay,
    required this.dueDay,
    required this.isActive,
    required this.createdAt,
  });

  factory CreditCardModel.fromFirestore(
      String creditCardId,
      Map<String, dynamic> data,
      ) {
    return CreditCardModel(
      creditCardId: creditCardId,
      cardName: data['cardName'] ?? '',
      bankName: data['bankName'] ?? '',
      creditLimit: (data['creditLimit'] as num?)?.toDouble() ?? 0.0,
      statementDay: data['statementDay'] ?? 1,
      dueDay: data['dueDay'] ?? 15,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'creditCardId': creditCardId,
      'cardName': cardName,
      'bankName': bankName,
      'creditLimit': creditLimit,
      'statementDay': statementDay,
      'dueDay': dueDay,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'creditCardId': creditCardId,
      'cardName': cardName,
      'bankName': bankName,
      'creditLimit': creditLimit,
      'statementDay': statementDay,
      'dueDay': dueDay,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CreditCardModel.fromJson(Map<String, dynamic> json) {
    return CreditCardModel(
      creditCardId: json['creditCardId'],
      cardName: json['cardName'],
      bankName: json['bankName'],
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0.0,
      statementDay: json['statementDay'] ?? 1,
      dueDay: json['dueDay'] ?? 15,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }


  CreditCardModel copyWith({
    String? creditCardId,
    String? cardName,
    String? bankName,
    double? creditLimit,
    double? currentUsed,
    int? statementDay,
    int? dueDay,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CreditCardModel(
      creditCardId: creditCardId ?? this.creditCardId,
      cardName: cardName ?? this.cardName,
      bankName: bankName ?? this.bankName,
      creditLimit: creditLimit ?? this.creditLimit,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  BillingCycle get billingCycle {
    final now = DateTime.now();

    DateTime statementThisMonth = DateTime(
      now.year,
      now.month,
      statementDay,
    );

    DateTime currentEnd;
    DateTime currentStart;

    if (now.isAfter(statementThisMonth) ||
        now.isAtSameMomentAs(statementThisMonth)) {
      currentEnd = DateTime(now.year, now.month + 1, statementDay);
      currentStart = DateTime(now.year, now.month, statementDay + 1);
    } else {
      currentEnd = statementThisMonth;
      currentStart = DateTime(now.year, now.month - 1, statementDay + 1);
    }

    final previousEnd = currentStart.subtract(const Duration(days: 1));

    final previousStart = DateTime(
      previousEnd.year,
      previousEnd.month - 1,
      statementDay + 1,
    );

    return BillingCycle(
      currentStart: currentStart,
      currentEnd: currentEnd,
      previousStart: previousStart,
      previousEnd: previousEnd,
      currentBillingCycleId:
      "${currentStart.year}-${currentStart.month.toString().padLeft(2, '0')}",
    );
  }
}
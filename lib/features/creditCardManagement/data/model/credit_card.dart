import 'package:cloud_firestore/cloud_firestore.dart';

class CreditCardModel {
  final String creditCardId;
  final String cardName;
  final String bankName;
  final double creditLimit;
  final int statementDay; // 1-31
  final int dueDay; // 1-31
  final bool isActive;
  final String? currentBillingCycleId;
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
    this.currentBillingCycleId,
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
      currentBillingCycleId: data['currentBillingCycleId'] ?? '',
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
      'currentBillingCycleId':currentBillingCycleId ?? '',
    };
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
    String? currentBillingCycleId,
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
      currentBillingCycleId: currentBillingCycleId ?? this.currentBillingCycleId,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class DailyExpenseSummary {
  final String id; // The document ID (dateId)
  final String date;
  final double total;
  final DateTime? repairedAt;
  final DateTime? updatedAt;

  DailyExpenseSummary({
    required this.id,
    required this.date,
    required this.total,
    this.repairedAt,
    this.updatedAt,
  });

  factory DailyExpenseSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return DailyExpenseSummary(
      id: doc.id,
      date: data['date'] as String? ?? '',
      // Safely handle both int and double from Firestore
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      // Convert Firestore Timestamp to Dart DateTime
      repairedAt: (data['repairedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
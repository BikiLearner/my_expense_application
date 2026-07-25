import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expence_app/core/constants/collection_name_constant.dart';

import '../../../../shared/models/month_stats.dart';
import '../../../../shared/models/year_stats.dart';

class HistoryDataSource {
  HistoryDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<YearStats?> fetchYearStats({
    required String uid,
    required String selectedYear,
  }) async {
    final doc = await _firestore
        .collection(CollectionName.users)
        .doc(uid)
        .collection(CollectionName.yearStats)
        .doc(selectedYear)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return YearStats.fromFirestore(
      doc.id,
      doc.data()!,
    );
  }

  Future<MonthStats?> fetchMonthStats({
    required String uid,
    required String selectedYear,
    required int selectedMonth,
  }) async {
    final monthId =
        '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';

    final doc = await _firestore
        .collection(CollectionName.users)
        .doc(uid)
        .collection(CollectionName.yearStats)
        .doc(selectedYear)
        .collection(CollectionName.months)
        .doc(monthId)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return MonthStats.fromFirestore(
      doc.id,
      doc.data()!,
    );
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/year_stats.dart';
import '../models/month_stats.dart';

class YearStatsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid =FirebaseAuth.instance.currentUser!.uid;


  // ---- Cache ----
  final Map<String, YearStats> _yearCache = {};
  final Map<String, MonthStats> _monthCache = {};

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ---- Getters ----
  YearStats? getYear(String year) => _yearCache[year];

  MonthStats? getMonth(String monthKey) => _monthCache[monthKey];

  // -------------------------------
  // Fetch YEAR stats (cached)
  // -------------------------------
  Future<void> fetchYear(String year, {bool force = false}) async {
    if (!force && _yearCache.containsKey(year)) {
      return; // ✅ cached
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('year_stats')
          .doc(year)
          .get();

      if (doc.exists) {
        _yearCache[year] = YearStats.fromFirestore(
          doc.id,
          doc.data()!,
        );
      } else {
        _yearCache.remove(year);
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('❌ Failed to fetch year stats: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // -------------------------------
  // Fetch MONTH stats (on demand)
  // monthKey = yyyy-MM
  // -------------------------------
  Future<void> fetchMonth({
    required String year,
    required String monthKey,
    bool force = false,
  }) async {
    if (!force && _monthCache.containsKey(monthKey)) {
      return; // ✅ cached
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('year_stats')
          .doc(year)
          .collection('months')
          .doc(monthKey)
          .get();

      if (doc.exists) {
        _monthCache[monthKey] = MonthStats.fromFirestore(
          doc.id,
          doc.data()!,
        );
      } else {
        _monthCache.remove(monthKey);
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('❌ Failed to fetch month stats: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // -------------------------------
  // Helpers
  // -------------------------------
  void clearMonthCache(String year) {
    _monthCache.removeWhere((key, _) => key.startsWith(year));
    notifyListeners();
  }

  void clearAllCache() {
    _yearCache.clear();
    _monthCache.clear();
    notifyListeners();
  }
}

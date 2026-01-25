import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../enums/expense_type.dart';
import '../models/expense_items.dart';

class AllExpensesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late SharedPreferences _prefs;
  bool _prefsReady = false;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  String _currentMonthKey = '';
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  String get currentMonthKey => _currentMonthKey;

  /// 🔥 Flat cache
  final List<ExpenseItem> _cache = [];
  List<ExpenseItem> get allExpenses => List.unmodifiable(_cache);

  StreamSubscription? _subscription;

  /// 🔥 Constructor (NO async)
  AllExpensesProvider() {
    _initPrefs();
  }

  /// 🧠 Async init (SAFE)
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _prefsReady = true;
  }

  /// 🧠 Restore cached data instantly
  void restoreCache(String monthKey) {
    if (!_prefsReady) return;

    final raw = _prefs.getString('expenses_cache_$monthKey');
    if (raw == null) return;

    final decoded = jsonDecode(raw) as List;
    _cache
      ..clear()
      ..addAll(decoded.map((e) => ExpenseItem.fromJson(e)));

    notifyListeners();
  }

  /// 💾 Persist cache
  Future<void> _persistCache() async {
    if (!_prefsReady) return;

    final encoded = jsonEncode(_cache.map((e) => e.toJson()).toList());

    await _prefs.setString('expenses_cache_$_currentMonthKey', encoded);
  }

  /// 🚀 Start month stream
  Future<void> setMonth({required String year, required int month}) async {
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';

    if (_currentMonthKey == monthKey) return;

    _currentMonthKey = monthKey;
    _isLoading = true;

    _cache.clear();
    restoreCache(monthKey);

    notifyListeners();

    await _subscription?.cancel();

    _subscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .orderBy(FieldPath.documentId)
        .startAt([monthKey])
        .endAt(['$monthKey\uf8ff'])
        .snapshots()
        .listen(_onDatesSnapshot);
  }

  /// 🔁 Dates snapshot
  Future<void> _onDatesSnapshot(QuerySnapshot snapshot) async {
    for (final dateDoc in snapshot.docs) {
      await _syncDate(dateDoc.id);
    }

    _isLoading = false;
    await _persistCache();
    notifyListeners();
  }

  /// 🔥 Sync items for a date
  Future<void> _syncDate(String dateId) async {
    final itemsSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(dateId)
        .collection('items')
        .get();

    _cache.removeWhere((e) => e.dateId == dateId);

    for (final doc in itemsSnapshot.docs) {
      _cache.add(ExpenseItem.fromFirestore(doc.id, doc.data(), dateId));
    }
  }

  /// 🔍 Local search
  List<ExpenseItem> search({
    String query = '',
    double min = 0,
    double max = double.infinity,
    ExpenseType? type,
  }) {
    final q = query.toLowerCase();

    return _cache.where((e) {
      final matchesQuery =
          q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q);

      final matchesAmount = e.amount >= min && e.amount <= max;
      final matchesType = type == null || e.type == type;

      return matchesQuery && matchesAmount && matchesType;
    }).toList();
  }

  /// 💰 Totals
  double totalOf(List<ExpenseItem> list) =>
      list.fold(0, (s, e) => s + e.amount);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

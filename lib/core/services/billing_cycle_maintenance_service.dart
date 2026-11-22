import 'package:expence_app/core/services/service_loader_getIt.dart';
import 'package:expence_app/core/services/session_maganger.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/creditCardManagement/domain/repository/credit_repo.dart';

class BillingCycleMaintenanceService {
  BillingCycleMaintenanceService._();
  static final instance = BillingCycleMaintenanceService._();

  static const _keyPrefix = 'billing_cycle_last_success_date_';
  bool _isRunning = false;

  Future<void> runIfNeeded() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      final now = DateTime.now(); // single source of time
      final today = _todayKey(now);

      final uid = SessionManager.instance.userRef.id; // per-user key
      final key = '$_keyPrefix$uid';

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(key) == today) return;
      debugPrint('BillingService getting called');
      final repo = sl<CreditRepository>();
      final cards = await repo.fetchCreditCards();


      var allSucceeded = true;
      for (final card in cards) {
        try {
          await repo
              .reconcileBillingCycles(card, now)
              .timeout(const Duration(seconds: 30));
        } catch (e, st) {
          allSucceeded = false; // keep going with other cards
          debugPrint('Maintenance failed for ${card.cardName}: $e');
          debugPrintStack(stackTrace: st);
        }
      }

      if (allSucceeded) {
        await prefs.setString(key, today);
      }
    } catch (e, st) {
      debugPrint('Billing maintenance failed: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _isRunning = false;
    }
  }

  String _todayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
import 'dart:async';

import 'package:expence_app/features/bank/presentation/provider/bank_provider.dart';
import 'package:expence_app/features/creditCardManagement/presentation/provider/credit_expense_provider.dart';
import 'package:expence_app/features/export/presentation/provider/export_provider.dart';
import 'package:expence_app/features/history/presentation/provider/all_expense_provider.dart';
import 'package:expence_app/features/history/presentation/provider/history_page_provider.dart';
import 'package:expence_app/features/history/presentation/provider/month_expense_provider.dart';
import 'package:expence_app/shared/providers/category_provider.dart';
import 'package:expence_app/shared/providers/home_navigation_provider.dart';
import 'package:expence_app/shared/providers/year_stat_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'core/routes/app_pages.dart';
import 'core/services/billing_cycle_maintenance_service.dart';
import 'core/services/service_loader_getIt.dart';
import 'core/services/session_maganger.dart';
import 'features/auth/presentation/provider/auth_provider.dart';
import 'features/expense/presentation/provider/expence_provider.dart';
import 'features/setting/provider/setting_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SessionManager.instance.initialize();
  if (!kIsWeb) {
    await Workmanager().initialize(callbackDispatcher);
  }

  ServiceLocator.init();

  // Start billing cycle maintenance asynchronously
  unawaited(BillingCycleMaintenanceService.instance.runIfNeeded());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => sl<AuthProvider>()),
        ChangeNotifierProvider(create: (_) => sl<ExpenseProvider>()),
        ChangeNotifierProvider(create: (_) => sl<CategoryProvider>()),
        ChangeNotifierProvider(lazy: false, create: (_) => sl<BankProvider>()),
        ChangeNotifierProvider(create: (_) => sl<CreditExpenseProvider>()),
        ChangeNotifierProvider(create: (_) => sl<HomeNavigationProvider>()),
        ChangeNotifierProvider(create: (_) => sl<HistoryPageProvider>()),

        //Not global
        ChangeNotifierProvider(create: (_) => sl<ExportProvider>()),
        ChangeNotifierProvider(create: (_) => sl<SettingsProvider>()),
        ChangeNotifierProvider(create: (_) => sl<MonthExpensesProvider>()),
        ChangeNotifierProvider(create: (_) => sl<AllExpensesProvider>()),
        ChangeNotifierProvider(create: (_) => sl<YearStatsProvider>()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: AppPages.router,
      ),
    );
  }
}

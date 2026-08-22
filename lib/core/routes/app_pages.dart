import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/analytics/provider/analytics_provider.dart';
import '../../features/analytics/screens/anaylitcs_scree.dart';
import '../../features/analytics/widgets/all_detail_screens.dart';
import '../../features/analytics/widgets/kpi_detail_screen.dart';
import '../../features/auth/presentation/screen/auth_wraper.dart';
import '../../features/auth/presentation/screen/login_screen.dart';
import '../../features/auth/presentation/screen/register_screen.dart';
import '../../features/bank/data/model/bank_model.dart';
import '../../features/bank/presentation/screens/bank_account_details_screen.dart';
import '../../features/bank/presentation/screens/bank_analysis_screen.dart';
import '../../features/bank/presentation/screens/bank_form_page.dart';
import '../../features/bank/presentation/screens/bank_list_page.dart';
import '../../features/creditCardManagement/data/model/billing_cycle_model.dart';
import '../../features/creditCardManagement/data/model/credit_card.dart';
import '../../features/creditCardManagement/presentation/provider/credit_card_payment_provider.dart';
import '../../features/creditCardManagement/presentation/screens/billing_detials_screen.dart';
import '../../features/creditCardManagement/presentation/screens/credit_card_detials_screen.dart';
import '../../features/creditCardManagement/presentation/screens/credit_card_from_page.dart';
import '../../features/creditCardManagement/presentation/screens/credit_card_screen.dart';
import '../../features/creditCardManagement/presentation/screens/credit_expense_overview_screen.dart';
import '../../features/creditCardManagement/presentation/screens/credit_expense_screen.dart';
import '../../features/creditCardManagement/presentation/screens/credit_payment_screen.dart';
import '../../features/expense/presentation/screens/expense_particular_day_overView.dart';
import '../../features/export/presentation/screens/export_data_page.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/history/presentation/widgets/bank_monthly_break_down_screen.dart';
import '../../features/history/presentation/widgets/expense_type_breakdown_screen.dart';
import '../../features/history/presentation/widgets/month_list_page.dart';
import '../../features/history/presentation/widgets/monthly_expense_page.dart';
import '../../features/history/presentation/widgets/search_expance_screen.dart';
import '../../features/setting/screens/setting_page.dart';
import '../../shared/enums/expense_type.dart';
import '../services/service_loader_getIt.dart';
import 'app_routes.dart';

class AppPages {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      // Auth
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const AuthWrapper(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      // Expense
      GoRoute(
        path: AppRoutes.expenseOverview,
        builder: (_, __) => const ExpensesOverviewPageParticularDay(),
      ),

      // History
      GoRoute(
        path: AppRoutes.history,
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.monthlyExpenseList,
        builder: (_, __) => const MonthlyExpensePageHolidingList(),
      ),
      GoRoute(
        path: AppRoutes.monthlyExpense,
        builder: (context, state) {
          final (label, monthKey) = state.extra! as (String, String);
          return MonthlyExpensePage(label: label, monthKey: monthKey);
        },
      ),
      GoRoute(
        path: AppRoutes.expenseTypeBreakdown,
        builder: (context, state) {
          final (type, monthKey) = state.extra! as (ExpenseType, String);
          return ExpenseTypeBreakdownScreen(type: type, monthKey: monthKey);
        },
      ),
      GoRoute(
        path: AppRoutes.bankMonthlyBreakdown,
        builder: (context, state) =>
            BankMonthlyBreakdownScreen(year: state.extra! as String),
      ),
      GoRoute(
        path: AppRoutes.searchExpense,
        builder: (_, __) => const SearchExpensesScreen(),
      ),
      GoRoute(
        path: AppRoutes.export,
        builder: (_, __) => const ExportDataPage(),
      ),
      GoRoute(
        path: AppRoutes.analytics,
        builder: (context, state) =>
            ExpenseAnalyticsScreen(year: state.extra! as String),
      ),
      GoRoute(
        path: AppRoutes.maintenance,
        builder: (_, __) => const ExpenseMaintenancePage(),
      ),

      // Bank
      GoRoute(
        path: AppRoutes.bank,
        builder: (_, __) => const BankPage(),
      ),
      GoRoute(
        path: AppRoutes.bankForm,
        builder: (_, __) => const BankFormPage(),
      ),
      GoRoute(
        path: AppRoutes.bankDetails,
        builder: (context, state) =>
            BankAccountDetailScreen(bank: state.extra! as BankModel),
      ),
      GoRoute(
        path: AppRoutes.bankAnalysis,
        builder: (context, state) =>
            BankAnalysisScreen(bank: state.extra! as BankModel),
      ),

      // Credit Card
      GoRoute(
        path: AppRoutes.credit,
        builder: (_, __) => const CreditExpenseScreen(),
      ),
      GoRoute(
        path: AppRoutes.creditCards,
        builder: (_, __) => const CreditCardScreen(),
      ),
      GoRoute(
        path: AppRoutes.creditForm,
        builder: (_, __) => const CreditCardFromPage(),
      ),
      GoRoute(
        path: AppRoutes.creditDetails,
        builder: (context, state) {
          final (creditCard) =
          state.extra! as CreditCardModel;

          return ChangeNotifierProvider(
            create: (_) => sl<CreditCardDetailsProvider>(
              param1: creditCard,
            ),
            child: const CreditCardDetailsScreen(),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.billingDetails,
        builder: (context, state) {
          final (
          provider,
          creditCard,
          billingCycle,
          isCurrentCycle,
          ) = state.extra! as (
          CreditCardDetailsProvider,
          CreditCardModel,
          BillingCycleModel,
          bool,
          );

          return ChangeNotifierProvider.value(
            value: provider,
            child: BillingCycleDetailsScreen(
              creditCard: creditCard,
              billingCycle: billingCycle,
              isCurrentCycle: isCurrentCycle,
            ),
          );
        },
      ),

      // app_pages.dart
      GoRoute(
        path: AppRoutes.creditPayment,
        builder: (context, state) {
          final (provider, billingCycle) =
          state.extra! as (CreditCardDetailsProvider, BillingCycleModel);
          provider.setBillingCycleId(billingCycle); // sync provider to tapped cycle
          return ChangeNotifierProvider.value(
            value: provider,
            child: const CreditPaymentScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.billingDetails,
        builder: (context, state) {
          final (creditCard, billingCycle, isCurrentCycle) =
              state.extra! as (CreditCardModel, BillingCycleModel, bool);
          return BillingCycleDetailsScreen(
            creditCard: creditCard,
            billingCycle: billingCycle,
            isCurrentCycle: isCurrentCycle,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.creditExpenseOverview,
        builder: (_, __) => const CreditExpensesOverviewPage(),
      ),

      // Analytics Details (provider passed via extra)
      GoRoute(
        path: AppRoutes.kpi,
        builder: (context, state) {
          final (provider, type) = state.extra! as (AnalyticsProvider, KpiType);
          return ChangeNotifierProvider.value(
            value: provider,
            child: KpiDetailScreen(kpiType: type),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.spendingHabits,
        builder: (context, state) => ChangeNotifierProvider.value(
          value: state.extra! as AnalyticsProvider,
          child: const SpendingHabitsDetailScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.monthlyTrend,
        builder: (context, state) => ChangeNotifierProvider.value(
          value: state.extra! as AnalyticsProvider,
          child: const MonthlyTrendDetailScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.category,
        builder: (context, state) => ChangeNotifierProvider.value(
          value: state.extra! as AnalyticsProvider,
          child: const CategoryDetailScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.topExpenses,
        builder: (context, state) => ChangeNotifierProvider.value(
          value: state.extra! as AnalyticsProvider,
          child: const TopExpensesDetailScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.bankUsage,
        builder: (context, state) => ChangeNotifierProvider.value(
          value: state.extra! as AnalyticsProvider,
          child: const BankUsageDetailScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.savings,
        builder: (context, state) => ChangeNotifierProvider.value(
          value: state.extra! as AnalyticsProvider,
          child: const SavingsDetailScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.behaviour,
        builder: (context, state) => ChangeNotifierProvider.value(
          value: state.extra! as AnalyticsProvider,
          child: const BehaviourDetailScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.heatmap,
        builder: (_, __) => ChangeNotifierProvider(
          create: (_) => sl<AnalyticsProvider>(),
          child: const HeatmapDetailScreen(),
        ),
      ),
    ],
  );
}

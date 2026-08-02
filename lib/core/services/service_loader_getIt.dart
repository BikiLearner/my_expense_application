import 'package:expence_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:expence_app/features/bank/data/datasource/bank_datasource.dart';
import 'package:expence_app/features/bank/data/repository/bank_repository_impl.dart';
import 'package:expence_app/features/bank/domain/repository/bank_repository.dart';
import 'package:expence_app/features/bank/presentation/provider/bank_provider.dart';
import 'package:expence_app/features/creditCardManagement/data/datasource/credit_firestore_datasource.dart';
import 'package:expence_app/features/creditCardManagement/data/repository/credit_repo_impl.dart';
import 'package:expence_app/features/creditCardManagement/domain/repository/credit_repo.dart';
import 'package:expence_app/features/creditCardManagement/presentation/provider/credit_expense_provider.dart';
import 'package:expence_app/features/expense/data/datasource/expense_firestore_datasource.dart';
import 'package:expence_app/features/expense/data/repository/expense_repository_impl.dart';
import 'package:expence_app/features/expense/domain/repository/expense_repository.dart'; // Make sure to import the domain repo
import 'package:expence_app/features/expense/presentation/provider/expence_provider.dart';
import 'package:expence_app/features/export/presentation/provider/export_provider.dart';
import 'package:expence_app/features/history/data/datesource/history_date_source.dart';
import 'package:expence_app/features/history/domain/repository/history_repo.dart';
// Imports from your project
import 'package:expence_app/features/history/presentation/provider/all_expense_provider.dart';
import 'package:expence_app/features/history/presentation/provider/history_page_provider.dart';
import 'package:expence_app/features/history/presentation/provider/month_expense_provider.dart';
import 'package:expence_app/features/setting/provider/setting_provider.dart';
import 'package:expence_app/shared/backend_parts/datasources/category_datesource.dart';
import 'package:expence_app/shared/backend_parts/repo/category_repo.dart';
import 'package:expence_app/shared/backend_parts/repoImpl/category_repo_impl.dart';
import 'package:expence_app/shared/providers/category_provider.dart';
import 'package:expence_app/shared/providers/home_navigation_provider.dart';
import 'package:expence_app/shared/providers/year_stat_provider.dart';
import 'package:get_it/get_it.dart';

import '../../features/creditCardManagement/data/model/billing_cycle_model.dart';
import '../../features/creditCardManagement/data/model/credit_card.dart';
import '../../features/creditCardManagement/presentation/provider/credit_card_payment_provider.dart';
import '../../features/history/data/repository/history_repo_impl.dart';

// Global ServiceLocator instance
final sl = GetIt.instance;

class ServiceLocator {
  ServiceLocator._();

  static void init() {
    // ⚠️ Registration order is important: DataSources -> Repositories -> Providers
    _registerDataSources();
    _registerRepositories();
    _registerProviders();
  }

  static void _registerDataSources() {
    sl.registerLazySingleton<ExpenseFirestoreDatasource>(
      () => ExpenseFirestoreDatasource(),
    );
    sl.registerLazySingleton<CategoryDateSource>(() => CategoryDateSource());
    sl.registerLazySingleton<BankDatasource>(() => BankDatasource());
    sl.registerLazySingleton<CreditFirestoreDatasource>(
      () => CreditFirestoreDatasource(),
    );
    sl.registerLazySingleton<HistoryDataSource>(() => HistoryDataSource());
  }

  static void _registerRepositories() {
    sl.registerLazySingleton<ExpenseRepository>(
      () => ExpenseRepositoryImpl(datasource: sl()),
    );
    sl.registerLazySingleton<CategoryRepo>(
      () => CategoryRepoImpl(datasource: sl()),
    );
    sl.registerLazySingleton<BankRepository>(
      () => BankRepositoryImpl(datasource: sl()),
    );

    sl.registerLazySingleton<CreditRepository>(
      () => CreditRepositoryImpl(datasource: sl()),
    );
    sl.registerLazySingleton<HistoryRepository>(
      () => HistoryRepositoryImpl(datasource: sl()),
    );
  }

  static void _registerProviders() {
    // Factory means a new instance is created every time the UI requests it
    sl.registerFactory(() => AuthProvider());
    sl.registerFactory(
      () => ExpenseProvider(repository: sl(), bankRepository: sl()),
    );
    sl.registerFactory(() => CategoryProvider(repository: sl()));
    sl.registerFactory(() => ExportProvider());
    sl.registerFactory(() => SettingsProvider());
    sl.registerFactory(() => MonthExpensesProvider());
    sl.registerFactory(() => AllExpensesProvider());
    sl.registerFactory(() => BankProvider(repository: sl()));
    sl.registerFactory(() => CreditExpenseProvider(repository: sl()));
    sl.registerFactory(() => YearStatsProvider());
    sl.registerFactory(() => HomeNavigationProvider());
    sl.registerFactoryParam<
        CreditCardDetailsProvider,
        CreditCardModel,
        void>(
          (creditCard, _) => CreditCardDetailsProvider(
        repository: sl(),
        bankRepository: sl(),
        expenseRepository: sl(),
        creditCard: creditCard,
      ),
    );
    sl.registerFactory(
      () => HistoryPageProvider(
        historyRepository: sl(),
        expenseRepo: sl(),
        creditRepo: sl(),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/app_database.dart';
import '../data/models/app_settings.dart';
import '../data/models/financial_summaries.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/dollar_tracker_repository.dart';
import '../data/repositories/savings_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/transaction_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(appDatabaseProvider).transactionDao);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(appDatabaseProvider).categoryDao);
});

final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  return SavingsRepository(ref.watch(appDatabaseProvider).savingsGoalDao);
});

final dollarTrackerRepositoryProvider = Provider<DollarTrackerRepository>((
  ref,
) {
  return DollarTrackerRepository(
    ref.watch(appDatabaseProvider).dollarExpenseDao,
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(sharedPreferencesProvider));
});

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return ref.watch(settingsRepositoryProvider).loadSettings();
  }

  Future<void> setBiometricEnabled(bool value) async {
    await ref.read(settingsRepositoryProvider).setBiometricEnabled(value);
    state = state.copyWith(biometricEnabled: value);
  }

  Future<void> setDollarAnnualLimit(double value) async {
    await ref.read(settingsRepositoryProvider).setDollarAnnualLimit(value);
    state = state.copyWith(dollarAnnualLimit: value);
  }

  Future<void> setDollarLimitYear(int value) async {
    await ref.read(settingsRepositoryProvider).setDollarLimitYear(value);
    state = state.copyWith(dollarLimitYear: value);
  }

  Future<void> setInitialBalance(double value) async {
    await ref.read(settingsRepositoryProvider).setInitialBalance(value);
    state = state.copyWith(initialBalance: value);
  }
}

final appSettingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

final categoriesProvider = StreamProvider((ref) {
  return ref.watch(categoryRepositoryProvider).watchMainCategories();
});

final dollarCategoriesProvider = StreamProvider((ref) {
  return ref.watch(categoryRepositoryProvider).watchDollarCategories();
});

final transactionsProvider = StreamProvider((ref) {
  return ref.watch(transactionRepositoryProvider).watchTransactions();
});

final savingsGoalsProvider = StreamProvider((ref) {
  return ref.watch(savingsRepositoryProvider).watchGoals();
});

final dollarExpensesProvider = StreamProvider((ref) {
  return ref.watch(dollarTrackerRepositoryProvider).watchExpenses();
});

final dollarExpensesForYearProvider =
    StreamProvider.family<List<DollarExpensesTableData>, int>((ref, year) {
      return ref
          .watch(dollarTrackerRepositoryProvider)
          .watchExpensesForYear(year);
    });

final balanceSummaryProvider = Provider<AsyncValue<BalanceSummary>>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final transactions = ref.watch(transactionsProvider);

  return transactions.whenData(
    (entries) => FinanceCalculators.balanceSummary(
      transactions: entries,
      initialBalance: settings.initialBalance,
    ),
  );
});

final currentMonthSummaryProvider = Provider<AsyncValue<MonthlyFinanceSummary>>(
  (ref) {
    final transactions = ref.watch(transactionsProvider);
    final month = DateTime.now();

    return transactions.whenData(
      (entries) => FinanceCalculators.monthlySummary(
        transactions: entries,
        month: month,
      ),
    );
  },
);

final monthlySummaryProvider =
    Provider.family<AsyncValue<MonthlyFinanceSummary>, DateTime>((ref, month) {
      final transactions = ref.watch(transactionsProvider);

      return transactions.whenData(
        (entries) => FinanceCalculators.monthlySummary(
          transactions: entries,
          month: month,
        ),
      );
    });

final monthlyAnalyticsProvider =
    Provider.family<AsyncValue<MonthlyAnalytics>, DateTime>((ref, month) {
      final transactions = ref.watch(transactionsProvider);
      final categories = ref.watch(categoriesProvider);

      if (transactions.hasError) {
        return AsyncError(
          transactions.error!,
          transactions.asError?.stackTrace ?? StackTrace.current,
        );
      }

      if (categories.hasError) {
        return AsyncError(
          categories.error!,
          categories.asError?.stackTrace ?? StackTrace.current,
        );
      }

      if (!transactions.hasValue || !categories.hasValue) {
        return const AsyncLoading();
      }

      return AsyncData(
        FinanceCalculators.monthlyAnalytics(
          transactions: transactions.value!,
          categories: categories.value!,
          month: month,
        ),
      );
    });

final dollarTrackerSummaryProvider = Provider<AsyncValue<DollarTrackerSummary>>(
  (ref) {
    final settings = ref.watch(appSettingsProvider);
    final expenses = ref.watch(dollarExpensesProvider);

    return expenses.whenData(
      (entries) => FinanceCalculators.dollarSummary(
        expenses: entries,
        annualLimit: settings.dollarAnnualLimit,
        year: settings.dollarLimitYear,
      ),
    );
  },
);

final dollarTrackerSummaryForYearProvider =
    Provider.family<AsyncValue<DollarTrackerSummary>, int>((ref, year) {
      final settings = ref.watch(appSettingsProvider);
      final expenses = ref.watch(dollarExpensesForYearProvider(year));

      return expenses.whenData(
        (entries) => FinanceCalculators.dollarSummary(
          expenses: entries,
          annualLimit: settings.dollarAnnualLimit,
          year: year,
        ),
      );
    });

final savingsInsightsProvider = Provider<AsyncValue<SavingsInsights>>((ref) {
  final transactions = ref.watch(transactionsProvider);

  return transactions.whenData(
    (entries) => FinanceCalculators.savingsInsights(
      transactions: entries,
      referenceMonth: DateTime.now(),
    ),
  );
});

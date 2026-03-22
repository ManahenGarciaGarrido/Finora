import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Core
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../database/local_database.dart';
import '../sync/sync_manager.dart';
import '../connectivity/connectivity_service.dart';
import '../security/biometric_service.dart'; // RF-03
import '../services/ai_service.dart'; // RF-21 / RF-22

// Features - Authentication
import '../../features/authentication/data/datasources/auth_remote_datasource.dart';
import '../../features/authentication/data/datasources/auth_local_datasource.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/domain/usecases/login_usecase.dart';
import '../../features/authentication/domain/usecases/register_usecase.dart';
import '../../features/authentication/domain/usecases/logout_usecase.dart';
import '../../features/authentication/domain/usecases/forgot_password_usecase.dart';
import '../../features/authentication/domain/usecases/reset_password_usecase.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';

// Features - Transactions
import '../../features/transactions/presentation/bloc/transaction_bloc.dart';

// Features - Categories
import '../../features/categories/presentation/bloc/category_bloc.dart';

// Features - Banks (RF-10)
import '../../features/banks/data/datasources/bank_remote_datasource.dart';
import '../../features/banks/data/repositories/bank_repository_impl.dart';
import '../../features/banks/domain/repositories/bank_repository.dart';
import '../../features/banks/domain/usecases/connect_bank_usecase.dart';
import '../../features/banks/domain/usecases/disconnect_bank_usecase.dart';
import '../../features/banks/domain/usecases/get_bank_accounts_usecase.dart';
import '../../features/banks/domain/usecases/get_institutions_usecase.dart';
import '../../features/banks/domain/usecases/get_sync_status_usecase.dart';
import '../../features/banks/domain/usecases/sync_bank_usecase.dart';
import '../../features/banks/domain/usecases/setup_bank_account_usecase.dart';
import '../../features/banks/domain/usecases/get_bank_cards_usecase.dart';
import '../../features/banks/domain/usecases/add_bank_card_usecase.dart';
import '../../features/banks/domain/usecases/delete_bank_card_usecase.dart';
import '../../features/banks/domain/usecases/import_csv_usecase.dart';
import '../../features/banks/domain/usecases/import_bank_transactions_usecase.dart';
import '../../features/banks/domain/usecases/exchange_public_token_usecase.dart';
import '../../features/banks/domain/usecases/import_selected_accounts_usecase.dart';
import '../../features/banks/presentation/bloc/bank_bloc.dart';

// Features - Investments
import '../../features/investments/data/datasources/investments_remote_datasource.dart';
import '../../features/investments/data/repositories/investments_repository_impl.dart';
import '../../features/investments/domain/repositories/investments_repository.dart';
import '../../features/investments/domain/usecases/get_profile_usecase.dart';
import '../../features/investments/domain/usecases/save_profile_usecase.dart';
import '../../features/investments/domain/usecases/get_portfolio_suggestion_usecase.dart';
import '../../features/investments/domain/usecases/simulate_returns_usecase.dart';
import '../../features/investments/domain/usecases/get_indices_usecase.dart';
import '../../features/investments/domain/usecases/get_glossary_usecase.dart';
import '../../features/investments/presentation/bloc/investment_bloc.dart';

// Features - Widget
import '../../features/widget/data/datasources/widget_remote_datasource.dart';
import '../../features/widget/data/repositories/widget_repository_impl.dart';
import '../../features/widget/domain/repositories/widget_repository.dart';
import '../../features/widget/presentation/bloc/widget_bloc.dart';
import '../../features/widget/services/widget_channel_service.dart';

// Features - OCR
import '../../features/ocr/data/datasources/ocr_remote_datasource.dart';
import '../../features/ocr/data/repositories/ocr_repository_impl.dart';
import '../../features/ocr/domain/repositories/ocr_repository.dart';
import '../../features/ocr/presentation/bloc/ocr_bloc.dart';

// Features - Fiscal
import '../../features/fiscal/data/datasources/fiscal_remote_datasource.dart';
import '../../features/fiscal/data/repositories/fiscal_repository_impl.dart';
import '../../features/fiscal/domain/repositories/fiscal_repository.dart';
import '../../features/fiscal/presentation/bloc/fiscal_bloc.dart';

// Features - Gamification
import '../../features/gamification/data/datasources/gamification_remote_datasource.dart';
import '../../features/gamification/data/repositories/gamification_repository_impl.dart';
import '../../features/gamification/domain/repositories/gamification_repository.dart';
import '../../features/gamification/presentation/bloc/gamification_bloc.dart';

// Features - Household
import '../../features/household/data/datasources/household_remote_datasource.dart';
import '../../features/household/data/repositories/household_repository_impl.dart';
import '../../features/household/domain/repositories/household_repository.dart';
import '../../features/household/presentation/bloc/household_bloc.dart';

// Features - Debts
import '../../features/debts/data/datasources/debts_remote_datasource.dart';
import '../../features/debts/data/repositories/debts_repository_impl.dart';
import '../../features/debts/domain/repositories/debts_repository.dart';
import '../../features/debts/domain/usecases/get_debts_usecase.dart';
import '../../features/debts/domain/usecases/create_debt_usecase.dart';
import '../../features/debts/domain/usecases/update_debt_usecase.dart';
import '../../features/debts/domain/usecases/delete_debt_usecase.dart';
import '../../features/debts/domain/usecases/get_strategies_usecase.dart';
import '../../features/debts/domain/usecases/calculate_loan_usecase.dart';
import '../../features/debts/presentation/bloc/debt_bloc.dart';

// Features - Goals (RF-18 / RF-19 / RF-20 / RF-21 / HU-07)
import '../../features/goals/data/datasources/goals_remote_datasource.dart';
import '../../features/goals/data/repositories/goals_repository_impl.dart';
import '../../features/goals/domain/repositories/goals_repository.dart';
import '../../features/goals/domain/usecases/get_goals_usecase.dart';
import '../../features/goals/domain/usecases/create_goal_usecase.dart';
import '../../features/goals/domain/usecases/update_goal_usecase.dart';
import '../../features/goals/domain/usecases/delete_goal_usecase.dart';
import '../../features/goals/domain/usecases/get_goal_progress_usecase.dart';
import '../../features/goals/domain/usecases/add_contribution_usecase.dart';
import '../../features/goals/domain/usecases/get_contributions_usecase.dart';
import '../../features/goals/domain/usecases/delete_contribution_usecase.dart';
import '../../features/goals/domain/usecases/get_recommendations_usecase.dart';
import '../../features/goals/presentation/bloc/goal_bloc.dart';

final sl = GetIt.instance;

/// Initialize all dependencies
/// This follows the dependency injection principle where:
/// - External dependencies are registered first
/// - Core utilities are registered next
/// - Data sources are registered
/// - Repositories are registered (implementing interfaces from domain)
/// - Use cases are registered
/// - BLoCs/ViewModels are registered last
Future<void> init() async {
  //! External
  await _initExternal();

  //! Core
  await _initCore();

  //! Features - Authentication
  await _initAuthentication();

  //! Features - Transactions & Categories
  await _initTransactions();

  //! Features - Investments
  await _initInvestments();

  //! Features - Debts
  await _initDebts();

  //! Features - Widget
  await _initWidget();

  //! Features - OCR
  await _initOcr();

  //! Features - Fiscal
  await _initFiscal();

  //! Features - Gamification
  await _initGamification();

  //! Features - Household
  await _initHousehold();

  //! Features - Goals (RF-18 / RF-19 / RF-20 / RF-21 / HU-07)
  await _initGoals();

  //! Features - Banks (RF-10)
  await _initBanks();
}

/// Initialize Authentication feature dependencies
Future<void> _initAuthentication() async {
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      forgotPasswordUseCase: sl(),
      resetPasswordUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      localDatabase: sl(),
    ),
  );

  // Data sources
  // Register local data source first since remote depends on it
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl(), localDataSource: sl()),
  );
}

/// Initialize Core dependencies
Future<void> _initCore() async {
  // Network
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  sl.registerLazySingleton(() => ApiClient());

  // Local Database (RNF-15)
  sl.registerLazySingleton(() => LocalDatabase());

  // Sync Manager (RNF-15)
  sl.registerLazySingleton(
    () => SyncManager(localDatabase: sl(), apiClient: sl(), networkInfo: sl()),
  );

  // Connectivity Service (RNF-15)
  sl.registerLazySingleton(
    () => ConnectivityService(connectivity: sl(), syncManager: sl()),
  );

  // RF-03: Biometric Service
  sl.registerLazySingleton(() => BiometricService());

  // RF-21 / RF-22: AI Service (predicciones ML + recomendaciones ahorro)
  sl.registerLazySingleton(() => AiService(apiClient: sl<ApiClient>()));
}

/// Initialize Transaction and Category BLoCs (RNF-06, RNF-15)
Future<void> _initTransactions() async {
  // Transaction BLoC - ahora con soporte offline
  sl.registerFactory(
    () => TransactionBloc(
      apiClient: sl(),
      localDatabase: sl(),
      networkInfo: sl(),
      syncManager: sl(),
    ),
  );

  // Category BLoC - ahora con caché Hive
  sl.registerFactory(() => CategoryBloc(apiClient: sl(), localDatabase: sl()));
}

/// Initialize External dependencies
Future<void> _initExternal() async {
  // Connectivity
  sl.registerLazySingleton(() => Connectivity());
}

/// Initialize Bank feature dependencies (RF-10)
Future<void> _initBanks() async {
  // BLoC
  sl.registerFactory(
    () => BankBloc(
      getInstitutions: sl(),
      connectBank: sl(),
      getBankAccounts: sl(),
      getSyncStatus: sl(),
      syncBank: sl(),
      disconnectBank: sl(),
      setupBankAccount: sl(),
      getBankCards: sl(),
      addBankCard: sl(),
      deleteBankCard: sl(),
      importCsv: sl(),
      importBankTransactions: sl(),
      exchangePublicToken: sl(),
      importSelectedAccounts: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetInstitutionsUseCase(sl()));
  sl.registerLazySingleton(() => ConnectBankUseCase(sl()));
  sl.registerLazySingleton(() => GetBankAccountsUseCase(sl()));
  sl.registerLazySingleton(() => GetSyncStatusUseCase(sl()));
  sl.registerLazySingleton(() => SyncBankUseCase(sl()));
  sl.registerLazySingleton(() => DisconnectBankUseCase(sl()));
  sl.registerLazySingleton(() => SetupBankAccountUseCase(sl()));
  sl.registerLazySingleton(() => GetBankCardsUseCase(sl()));
  sl.registerLazySingleton(() => AddBankCardUseCase(sl()));
  sl.registerLazySingleton(() => DeleteBankCardUseCase(sl()));
  sl.registerLazySingleton(() => ImportCsvUseCase(sl()));
  sl.registerLazySingleton(() => ImportBankTransactionsUseCase(sl())); // RF-11
  sl.registerLazySingleton(
    () => ExchangePublicTokenUseCase(sl()),
  ); // RF-10 Plaid
  sl.registerLazySingleton(
    () => ImportSelectedAccountsUseCase(sl()),
  ); // RF-10 selección

  // Repository
  sl.registerLazySingleton<BankRepository>(
    () => BankRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<BankRemoteDataSource>(
    () => BankRemoteDataSourceImpl(apiClient: sl()),
  );
}

/// Investments feature dependencies
Future<void> _initInvestments() async {
  sl.registerFactory(
    () => InvestmentBloc(
      getProfile: sl(),
      saveProfile: sl(),
      getPortfolioSuggestion: sl(),
      simulateReturns: sl(),
      getIndices: sl(),
      getGlossary: sl(),
      repository: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => SaveProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetPortfolioSuggestionUseCase(sl()));
  sl.registerLazySingleton(() => SimulateReturnsUseCase(sl()));
  sl.registerLazySingleton(() => GetIndicesUseCase(sl()));
  sl.registerLazySingleton(() => GetGlossaryUseCase(sl()));
  sl.registerLazySingleton<InvestmentsRepository>(
    () => InvestmentsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<InvestmentsRemoteDataSource>(
    () => InvestmentsRemoteDataSourceImpl(sl()),
  );
}

/// Debts feature dependencies
Future<void> _initDebts() async {
  sl.registerFactory(
    () => DebtBloc(
      getDebts: sl(),
      createDebt: sl(),
      updateDebt: sl(),
      deleteDebt: sl(),
      getStrategies: sl(),
      calculateLoan: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetDebtsUseCase(sl()));
  sl.registerLazySingleton(() => CreateDebtUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDebtUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDebtUseCase(sl()));
  sl.registerLazySingleton(() => GetStrategiesUseCase(sl()));
  sl.registerLazySingleton(() => CalculateLoanUseCase(sl()));
  sl.registerLazySingleton<DebtsRepository>(() => DebtsRepositoryImpl(sl()));
  sl.registerLazySingleton<DebtsRemoteDataSource>(
    () => DebtsRemoteDataSourceImpl(sl()),
  );
}

/// Widget feature dependencies
Future<void> _initWidget() async {
  sl.registerLazySingleton(() => WidgetChannelService());
  sl.registerFactory(() => WidgetBloc(sl(), sl()));
  sl.registerLazySingleton<WidgetRepository>(() => WidgetRepositoryImpl(sl()));
  sl.registerLazySingleton<WidgetRemoteDataSource>(
    () => WidgetRemoteDataSourceImpl(sl()),
  );
}

/// OCR feature dependencies
Future<void> _initOcr() async {
  sl.registerFactory(() => OcrBloc(sl()));
  sl.registerLazySingleton<OcrRepository>(() => OcrRepositoryImpl(sl()));
  sl.registerLazySingleton<OcrRemoteDataSource>(
    () => OcrRemoteDataSourceImpl(sl()),
  );
}

/// Fiscal feature dependencies
Future<void> _initFiscal() async {
  sl.registerFactory(() => FiscalBloc(sl()));
  sl.registerLazySingleton<FiscalRepository>(() => FiscalRepositoryImpl(sl()));
  sl.registerLazySingleton<FiscalRemoteDataSource>(
    () => FiscalRemoteDataSourceImpl(sl()),
  );
}

/// Gamification feature dependencies
Future<void> _initGamification() async {
  sl.registerFactory(() => GamificationBloc(sl()));
  sl.registerLazySingleton<GamificationRepository>(
    () => GamificationRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<GamificationRemoteDataSource>(
    () => GamificationRemoteDataSourceImpl(sl()),
  );
}

/// Household feature dependencies
Future<void> _initHousehold() async {
  sl.registerFactory(() => HouseholdBloc(sl()));
  sl.registerLazySingleton<HouseholdRepository>(
    () => HouseholdRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<HouseholdRemoteDataSource>(
    () => HouseholdRemoteDataSourceImpl(sl()),
  );
}

/// Goals feature dependencies (RF-18 / RF-19 / RF-20 / RF-21 / HU-07)
Future<void> _initGoals() async {
  // Bloc
  sl.registerFactory(
    () => GoalBloc(
      getGoals: sl(),
      createGoal: sl(),
      updateGoal: sl(),
      deleteGoal: sl(),
      getGoalProgress: sl(),
      addContribution: sl(),
      getContributions: sl(),
      deleteContribution: sl(),
      getRecommendations: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetGoalsUseCase(sl()));
  sl.registerLazySingleton(() => CreateGoalUseCase(sl()));
  sl.registerLazySingleton(() => UpdateGoalUseCase(sl()));
  sl.registerLazySingleton(() => DeleteGoalUseCase(sl()));
  sl.registerLazySingleton(() => GetGoalProgressUseCase(sl()));
  sl.registerLazySingleton(() => AddContributionUseCase(sl()));
  sl.registerLazySingleton(() => GetContributionsUseCase(sl()));
  sl.registerLazySingleton(() => DeleteContributionUseCase(sl()));
  sl.registerLazySingleton(() => GetRecommendationsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<GoalsRepository>(() => GoalsRepositoryImpl(sl()));

  // Data sources
  sl.registerLazySingleton<GoalsRemoteDataSource>(
    () => GoalsRemoteDataSourceImpl(sl()),
  );
}

/// Reset all dependencies (useful for testing)
Future<void> reset() async {
  await sl.reset();
}

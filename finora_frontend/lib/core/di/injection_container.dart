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

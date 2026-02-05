import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Core
import '../network/api_client.dart';
import '../network/network_info.dart';

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
  //! Features - Authentication
  await _initAuthentication();

  //! Core
  await _initCore();

  //! External
  await _initExternal();
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
    () => AuthRemoteDataSourceImpl(
      apiClient: sl(),
      localDataSource: sl(),
    ),
  );
}

/// Initialize Core dependencies
Future<void> _initCore() async {
  // Network
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  sl.registerLazySingleton(() => ApiClient());
}

/// Initialize External dependencies
Future<void> _initExternal() async {
  // Connectivity
  sl.registerLazySingleton(() => Connectivity());
}

/// Reset all dependencies (useful for testing)
Future<void> reset() async {
  await sl.reset();
}

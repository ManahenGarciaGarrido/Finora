import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/constants/app_constants.dart';
import 'core/database/local_database.dart';
import 'core/network/api_client.dart';
import 'core/connectivity/connectivity_service.dart';
import 'core/utils/platform_version_helper.dart';
import 'core/utils/ios_version_helper.dart';
import 'core/utils/app_startup_tracker.dart';
import 'features/authentication/data/datasources/auth_local_datasource.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/transactions/presentation/bloc/transaction_bloc.dart';
import 'features/transactions/presentation/bloc/transaction_event.dart';
import 'features/categories/presentation/bloc/category_bloc.dart';
import 'features/banks/presentation/bloc/bank_bloc.dart';
import 'features/authentication/presentation/pages/splash_page.dart';
import 'features/authentication/presentation/pages/login_page.dart';
import 'features/authentication/presentation/pages/register_page.dart';
import 'features/authentication/presentation/pages/forgot_password_page.dart';
import 'features/authentication/presentation/pages/reset_password_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/transactions/presentation/pages/add_transaction_page.dart';
import 'features/transactions/presentation/pages/edit_transaction_page.dart';
import 'features/transactions/domain/entities/transaction_entity.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';
import 'core/services/app_settings_service.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/app_strings.dart';
import 'shared/widgets/offline_indicator.dart';

// TESTING: Descomenta las siguientes líneas para probar los widgets de compatibilidad
// import 'core/utils/platform_compatibility_example.dart';  // Android
// import 'core/utils/ios_compatibility_example.dart';       // iOS

/// Main entry point of the application
/// Demonstrates Clean Architecture with Dependency Injection
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // RNF-08: Iniciar tracker de arranque para medir tiempos de inicio
  AppStartupTracker.markAppStart();

  // Initialize dependency injection
  // This sets up all dependencies following the dependency inversion principle
  await di.init();

  // RNF-15 / HU-15: Inicializar Hive PRIMERO de forma secuencial.
  // LocalDatabase debe estar completamente listo antes de que ConnectivityService
  // u otros servicios puedan disparar eventos que accedan a los boxes de Hive
  // (ej. sync automático, LoadTransactions al navegar desde SplashPage).
  // Ejecutarlo en parallel con connectivityService causaba "Box not found".
  final localDatabase = di.sl<LocalDatabase>();
  await localDatabase.init();

  // RNF-08: Inicializar el resto de servicios en paralelo una vez Hive está listo.
  // ConnectivityService, PlatformVersionHelper e IOSVersionHelper son independientes
  // entre sí y de LocalDatabase, por lo que pueden ejecutarse concurrentemente.
  final connectivityService = di.sl<ConnectivityService>();
  await Future.wait([
    connectivityService.init(),
    PlatformVersionHelper.initialize(),
    IOSVersionHelper.initialize(),
  ]);

  // RNF-08: Registrar tiempo de init completado
  AppStartupTracker.markInitComplete();

  // RNF-13: Cargar ajustes de idioma y moneda persistidos
  await AppSettingsService().load();

  // Cargar paleta de colores persistida
  await ThemeService().load();

  runApp(MyApp(connectivityService: connectivityService));
}

/// Root widget of the application
class MyApp extends StatefulWidget {
  final ConnectivityService connectivityService;

  const MyApp({super.key, required this.connectivityService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final TransactionBloc _transactionBloc;
  StreamSubscription<bool>? _syncSubscription;
  StreamSubscription<void>? _unauthorizedSubscription;
  bool _isHandlingUnauthorized = false;

  // RNF-13: Current locale — updated when AppSettingsService.localeNotifier changes
  late Locale _currentLocale;

  // RNF-13: Key que fuerza reconstrucción total del árbol de widgets al cambiar idioma
  Key _appKey = UniqueKey();

  // RNF-13: Estado del overlay de carga al cambiar idioma
  bool _showLangOverlay = false;
  String _langOverlayText = '';

  @override
  void initState() {
    super.initState();
    _currentLocale = AppSettingsService().localeNotifier.value;

    // Listen to locale changes (Fix-12: auto-refresh on language change)
    AppSettingsService().localeNotifier.addListener(_onLocaleChanged);

    // Listen to currency changes — trigger full app rebuild so all currency
    // displays update immediately
    AppSettingsService().currencyNotifier.addListener(_onCurrencyChanged);

    // Escuchar cambios de tema de color
    ThemeService().paletteNotifier.addListener(_onThemeChanged);

    // No disparar LoadTransactions aquí: el token JWT aún no está configurado
    // en ApiClient en este punto del ciclo de vida. Se dispara desde HomePage
    // una vez que la autenticación se ha completado.
    _transactionBloc = di.sl<TransactionBloc>();

    // Escuchar sincronización completada para recargar transacciones
    _syncSubscription = widget.connectivityService.onSyncComplete.listen((_) {
      debugPrint('MyApp: Sync completado, recargando transacciones...');
      _transactionBloc.add(LoadTransactions());
    });

    // Escuchar token expirado (401) para forzar cierre de sesión
    final apiClient = di.sl<ApiClient>();
    _unauthorizedSubscription = apiClient.onUnauthorized.listen((_) {
      _handleTokenExpired();
    });
  }

  /// Cierra sesión automáticamente cuando el token ha expirado
  Future<void> _handleTokenExpired() async {
    // Evitar múltiples ejecuciones simultáneas
    if (_isHandlingUnauthorized) return;
    _isHandlingUnauthorized = true;

    debugPrint('MyApp: Token expirado, cerrando sesión automáticamente...');

    try {
      // Limpiar token del ApiClient
      final apiClient = di.sl<ApiClient>();
      apiClient.clearToken();

      // Limpiar token almacenado
      final localDataSource = di.sl<AuthLocalDataSource>();
      await localDataSource.clearToken();
      await localDataSource.clearCache();
    } catch (e) {
      debugPrint('MyApp: Error limpiando datos de sesión: $e');
    }

    // Navegar a login
    final navigator = _navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);

      // Mostrar mensaje al usuario
      final context = navigator.context;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Tu sesión ha expirado. Por favor, inicia sesión de nuevo.',
            ),
            backgroundColor: Colors.orange[700],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    _isHandlingUnauthorized = false;
  }

  void _onCurrencyChanged() {
    setState(() {
      _appKey = UniqueKey();
    });
  }

  void _onLocaleChanged() {
    final newLocale = AppSettingsService().localeNotifier.value;
    final newStrings = AppStrings.forLocale(newLocale.languageCode);

    // Mostrar overlay de carga ya en el NUEVO idioma y forzar reconstrucción total
    setState(() {
      _currentLocale = newLocale;
      _appKey = UniqueKey();
      _langOverlayText = newStrings.changingLanguage;
      _showLangOverlay = true;
    });

    // Ocultar overlay tras 700 ms — tiempo suficiente para que el árbol reconstruya
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showLangOverlay = false);
    });
  }

  void _onThemeChanged() {
    setState(() => _appKey = UniqueKey());
  }

  @override
  void dispose() {
    AppSettingsService().localeNotifier.removeListener(_onLocaleChanged);
    AppSettingsService().currencyNotifier.removeListener(_onCurrencyChanged);
    ThemeService().paletteNotifier.removeListener(_onThemeChanged);
    _syncSubscription?.cancel();
    _unauthorizedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
        BlocProvider.value(value: _transactionBloc),
        // RNF-08: CategoryBloc se registra sin disparar LoadCategories aquí.
        // Las categorías solo se necesitan en AddTransactionPage y EditTransactionPage,
        // por lo que se cargan de forma lazy cuando el usuario accede a esas pantallas.
        BlocProvider(create: (_) => di.sl<CategoryBloc>()),
        // RF-10: Open Banking PSD2 — bank accounts and connections
        BlocProvider(create: (_) => di.sl<BankBloc>()),
      ],
      child: MaterialApp(
        key: _appKey,
        navigatorKey: _navigatorKey,
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: _currentLocale,
        // RNF-13: Registrar AppLocalizations + delegates globales de Material/Cupertino
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppStrings.supportedLocales,
        home: const SplashPage(),
        routes: {
          '/splash': (context) => const SplashPage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/home': (context) => const HomePage(),
          '/forgot-password': (context) => const ForgotPasswordPage(),
          '/add-transaction': (context) => const AddTransactionPage(),
        },
        onGenerateRoute: (settings) {
          debugPrint('=== ROUTE DEBUG ===');
          debugPrint('Route name: ${settings.name}');
          debugPrint('Arguments: ${settings.arguments}');

          // Handle /edit-transaction route (RF-06)
          if (settings.name == '/edit-transaction') {
            final transaction = settings.arguments as TransactionEntity?;
            if (transaction != null) {
              return MaterialPageRoute(
                builder: (context) =>
                    EditTransactionPage(transaction: transaction),
                settings: settings,
              );
            }
          }

          // Handle /reset-password route with token parameter
          if (settings.name?.startsWith('/reset-password') ?? false) {
            // Try to get token from arguments first (internal navigation)
            String? token = settings.arguments as String?;

            // If no arguments, try to extract token from query parameters (web URL)
            if (token == null && settings.name != null) {
              try {
                final uri = Uri.parse(settings.name!);
                token = uri.queryParameters['token'];
                debugPrint('Token extracted from URL: $token');
              } catch (e) {
                debugPrint('Error parsing URL: $e');
              }
            }

            if (token != null && token.isNotEmpty) {
              debugPrint(
                'Navigating to ResetPasswordPage with token: ${token.substring(0, 10)}...',
              );
              return MaterialPageRoute(
                builder: (context) => ResetPasswordPage(token: token!),
                settings: settings,
              );
            } else {
              debugPrint('ERROR: No token found, redirecting to login');
              return MaterialPageRoute(builder: (context) => const LoginPage());
            }
          }
          return null;
        },
        builder: (context, child) {
          // RNF-11: Respetar preferencias de accesibilidad del sistema
          // textScaleFactor: clamp entre 0.85x y 1.5x para garantizar legibilidad
          // sin romper el layout en textos muy grandes
          final mediaQuery = MediaQuery.of(context);
          final textScaler = mediaQuery.textScaler.clamp(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.5,
          );
          final appContent = MediaQuery(
            data: mediaQuery.copyWith(textScaler: textScaler),
            // Envolver toda la app con el indicador offline (RNF-15)
            child: OfflineIndicator(
              connectivityService: widget.connectivityService,
              child: child ?? const SizedBox.shrink(),
            ),
          );

          // RNF-13: Overlay de carga al cambiar idioma — ya en el nuevo idioma
          if (!_showLangOverlay) return appContent;

          return Stack(
            children: [
              appContent,
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _showLangOverlay ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    color: const Color(0xFF1A1A2E).withValues(alpha: 0.85),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _langOverlayText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

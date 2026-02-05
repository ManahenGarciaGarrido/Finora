import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/constants/app_constants.dart';
import 'core/utils/platform_version_helper.dart';
import 'core/utils/ios_version_helper.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/pages/splash_page.dart';
import 'features/authentication/presentation/pages/login_page.dart';
import 'features/authentication/presentation/pages/register_page.dart';
import 'features/authentication/presentation/pages/forgot_password_page.dart';
import 'features/authentication/presentation/pages/reset_password_page.dart';
import 'features/home/presentation/pages/home_page.dart';

// TESTING: Descomenta las siguientes líneas para probar los widgets de compatibilidad
// import 'core/utils/platform_compatibility_example.dart';  // Android
// import 'core/utils/ios_compatibility_example.dart';       // iOS

/// Main entry point of the application
/// Demonstrates Clean Architecture with Dependency Injection
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  // This sets up all dependencies following the dependency inversion principle
  await di.init();

  // Inicializar cache de versiones de plataforma para verificación de compatibilidad
  // Esto detecta la versión de Android/iOS y cachea la información del dispositivo
  await PlatformVersionHelper.initialize();  // Android
  await IOSVersionHelper.initialize();        // iOS

  // TESTING: Descomenta las siguientes líneas para ver información de compatibilidad en logs
  // final androidCompatInfo = await PlatformVersionHelper.getCompatibilityInfo();
  // final iosCompatInfo = await IOSVersionHelper.getCompatibilityInfo();
  // debugPrint('=== INFORMACIÓN DE COMPATIBILIDAD ===');
  // debugPrint(androidCompatInfo);
  // debugPrint(iosCompatInfo);
  // debugPrint('====================================');

  runApp(const MyApp());
}

/// Root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // Provide BLoCs to the entire app
      // BLoCs are injected via the service locator
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SplashPage(),
        routes: {
          '/splash': (context) => const SplashPage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/home': (context) => const HomePage(),
          '/forgot-password': (context) => const ForgotPasswordPage(),
        },
        onGenerateRoute: (settings) {
          debugPrint('=== ROUTE DEBUG ===');
          debugPrint('Route name: ${settings.name}');
          debugPrint('Arguments: ${settings.arguments}');

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
              debugPrint('Navigating to ResetPasswordPage with token: ${token.substring(0, 10)}...');
              return MaterialPageRoute(
                builder: (context) => ResetPasswordPage(token: token!),
                settings: settings,
              );
            } else {
              debugPrint('ERROR: No token found, redirecting to login');
              return MaterialPageRoute(
                builder: (context) => const LoginPage(),
              );
            }
          }
          return null;
        },
      ),
    );
  }
}

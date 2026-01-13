import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/constants/app_constants.dart';
import 'core/utils/platform_version_helper.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/pages/login_page.dart';

// TESTING: Descomenta la siguiente línea para probar el widget de compatibilidad de Android
// import 'core/utils/platform_compatibility_example.dart';

/// Main entry point of the application
/// Demonstrates Clean Architecture with Dependency Injection
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  // This sets up all dependencies following the dependency inversion principle
  await di.init();

  // Inicializar cache de versión de Android para verificación de compatibilidad
  // Esto detecta la versión de Android y cachea la información del dispositivo
  await PlatformVersionHelper.initialize();

  // TESTING: Descomenta las siguientes líneas para ver información de compatibilidad en logs
  // final compatInfo = await PlatformVersionHelper.getCompatibilityInfo();
  // debugPrint('=== INFORMACIÓN DE COMPATIBILIDAD ===');
  // debugPrint(compatInfo);
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
        home: const LoginPage(),

        // TESTING: Para probar el widget de compatibilidad de Android:
        // 1. Descomenta el import de 'platform_compatibility_example.dart' al inicio del archivo
        // 2. Reemplaza temporalmente 'const LoginPage()' con:
        //    const CompatibilityDemoWidget()
        //
        // O agrega un FloatingActionButton en LoginPage con:
        // onPressed: () {
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => const CompatibilityDemoWidget(),
        //     ),
        //   );
        // }
        //
        // Esto mostrará:
        // - Versión de Android del dispositivo/emulador
        // - API Level actual
        // - Fabricante y modelo
        // - Lista de todas las características soportadas (notificaciones, storage, etc.)
      ),
    );
  }
}

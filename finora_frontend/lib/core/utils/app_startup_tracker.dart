/// RNF-08: Tracker de tiempo de inicio de la aplicación
///
/// Mide los tiempos clave del proceso de arranque para:
/// - Verificar cumplimiento del criterio cold start < 3s
/// - Verificar cumplimiento del criterio warm start < 1s
/// - Permitir profiling de inicialización
///
/// Uso:
/// ```dart
/// AppStartupTracker.markAppStart();      // Al inicio de main()
/// AppStartupTracker.markInitComplete();  // Tras inicialización de servicios
/// AppStartupTracker.markSplashComplete();// Al navegar fuera del splash
/// AppStartupTracker.markDashboardReady();// Cuando el dashboard está listo
/// AppStartupTracker.printReport();       // Imprime el informe completo
/// ```
class AppStartupTracker {
  AppStartupTracker._();

  static DateTime? _appStart;
  static DateTime? _initComplete;
  static DateTime? _splashComplete;
  static DateTime? _dashboardReady;

  /// Registra el inicio del proceso main().
  /// Llamar como primera línea de main() tras ensureInitialized.
  static void markAppStart() {
    _appStart = DateTime.now();
  }

  /// Registra la finalización de la inicialización de servicios
  /// (DI, Hive, Connectivity, Platform helpers).
  static void markInitComplete() {
    _initComplete = DateTime.now();
    _log('Init de servicios completado en ${_elapsed(_appStart, _initComplete)}ms');
  }

  /// Registra cuando el splash navega a la siguiente pantalla.
  static void markSplashComplete() {
    _splashComplete = DateTime.now();
    final splashMs = _elapsed(_appStart, _splashComplete);
    _log('Splash completado en ${splashMs}ms (objetivo: < 1000ms)');
    if (splashMs > 1000) {
      _log('⚠️  ADVERTENCIA RNF-08: Splash superó 1000ms (actual: ${splashMs}ms)');
    }
  }

  /// Registra cuando el dashboard está completamente renderizado con datos.
  /// Llamar desde HomePage cuando los datos iniciales ya se muestran.
  static void markDashboardReady() {
    _dashboardReady = DateTime.now();
    printReport();
  }

  /// Imprime el informe completo de tiempos de inicio.
  static void printReport() {
    if (_appStart == null) return;

    final now = DateTime.now();
    final totalMs = _elapsed(_appStart, _dashboardReady ?? now);
    final initMs = _elapsed(_appStart, _initComplete);
    final splashMs = _elapsed(_appStart, _splashComplete);

    // ignore: avoid_print
    print('╔══════════════════════════════════════════╗');
    // ignore: avoid_print
    print('║       RNF-08: Startup Performance        ║');
    // ignore: avoid_print
    print('╠══════════════════════════════════════════╣');
    // ignore: avoid_print
    print('║  Init servicios:   ${_pad(initMs)}ms              ║');
    // ignore: avoid_print
    print('║  Splash completo:  ${_pad(splashMs)}ms  (obj<1000) ║');
    // ignore: avoid_print
    print('║  Dashboard listo:  ${_pad(totalMs)}ms  (obj<3000) ║');
    // ignore: avoid_print
    print('╠══════════════════════════════════════════╣');
    final coldStatus = totalMs < 3000 ? '✅ CUMPLE' : '❌ INCUMPLE';
    final splashStatus = splashMs < 1000 ? '✅ CUMPLE' : '❌ INCUMPLE';
    // ignore: avoid_print
    print('║  Cold start < 3s:  $coldStatus                ║');
    // ignore: avoid_print
    print('║  Splash < 1s:      $splashStatus               ║');
    // ignore: avoid_print
    print('╚══════════════════════════════════════════╝');
  }

  static int _elapsed(DateTime? from, DateTime? to) {
    if (from == null || to == null) return -1;
    return to.difference(from).inMilliseconds;
  }

  static String _pad(int ms) {
    return ms.toString().padLeft(4);
  }

  static void _log(String message) {
    // ignore: avoid_print
    print('[AppStartupTracker] $message');
  }
}

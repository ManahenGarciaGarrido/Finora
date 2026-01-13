import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Utilidad para manejar características específicas de versión de iOS
/// con fallbacks para funcionalidades no disponibles en versiones antiguas.
///
/// Esta clase proporciona métodos para verificar la versión de iOS
/// y habilitar/deshabilitar características según la compatibilidad.
class IOSVersionHelper {
  static const MethodChannel _channel =
      MethodChannel('com.finora.app/platform_version');

  /// Versión mínima soportada: iOS 13.0
  static const double minSupportedVersion = 13.0;

  /// iOS 13 (2019)
  static const double iOS13 = 13.0;

  /// iOS 14 (2020)
  static const double iOS14 = 14.0;

  /// iOS 15 (2021)
  static const double iOS15 = 15.0;

  /// iOS 16 (2022)
  static const double iOS16 = 16.0;

  /// iOS 17 (2023)
  static const double iOS17 = 17.0;

  /// iOS 18 (2024)
  static const double iOS18 = 18.0;

  /// Cache de la versión de iOS
  static double? _cachedIOSVersion;

  /// Cache de información del dispositivo
  static Map<String, dynamic>? _cachedDeviceInfo;

  /// Verifica si la plataforma actual es iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Obtiene la versión de iOS actual (e.g., 13.0, 14.5, 15.2)
  /// Retorna 0.0 si no es iOS o si no se puede determinar
  static Future<double> getIOSVersion() async {
    if (!isIOS) return 0.0;

    // Usar cache si está disponible
    if (_cachedIOSVersion != null) {
      return _cachedIOSVersion!;
    }

    try {
      final double version = await _channel.invokeMethod('getIOSVersionNumber');
      _cachedIOSVersion = version;
      return version;
    } catch (e) {
      debugPrint('Error obteniendo versión de iOS: $e');
      // Si falla, asumimos la versión mínima soportada
      return minSupportedVersion;
    }
  }

  /// Obtiene el nombre de la versión de iOS (e.g., "13.0", "14.5.1")
  static Future<String> getIOSVersionName() async {
    if (!isIOS) return 'N/A';

    try {
      final String versionName =
          await _channel.invokeMethod('getIOSVersion');
      return versionName;
    } catch (e) {
      debugPrint('Error obteniendo nombre de versión de iOS: $e');
      return 'Unknown';
    }
  }

  /// Obtiene información completa del dispositivo iOS
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    if (!isIOS) {
      return {
        'platform': 'non-ios',
        'systemVersion': 0.0,
      };
    }

    // Usar cache si está disponible
    if (_cachedDeviceInfo != null) {
      return _cachedDeviceInfo!;
    }

    try {
      final Map<dynamic, dynamic> deviceInfo =
          await _channel.invokeMethod('getDeviceInfo');
      _cachedDeviceInfo = Map<String, dynamic>.from(deviceInfo);
      return _cachedDeviceInfo!;
    } catch (e) {
      debugPrint('Error obteniendo información del dispositivo iOS: $e');
      return {
        'platform': 'ios',
        'systemVersion': minSupportedVersion,
        'error': e.toString(),
      };
    }
  }

  /// Verifica si la versión de iOS es al menos la especificada
  static Future<bool> isAtLeast(double version) async {
    if (!isIOS) return false;

    try {
      final bool result = await _channel.invokeMethod(
        'isAtLeastVersion',
        {'version': version},
      );
      return result;
    } catch (e) {
      debugPrint('Error verificando versión de iOS: $e');
      // Fallback: usar el método de obtener versión
      final currentVersion = await getIOSVersion();
      return currentVersion >= version;
    }
  }

  /// Versión sincrónica de isAtLeast (usa cache)
  /// IMPORTANTE: Debe llamarse getIOSVersion() primero para popular el cache
  static bool isAtLeastSync(double version) {
    if (!isIOS) return false;
    if (_cachedIOSVersion == null) {
      debugPrint(
          'Advertencia: Cache de versión no inicializado. Llama getIOSVersion() primero.');
      // Asumimos que cumple con la versión mínima
      return version >= minSupportedVersion;
    }
    return _cachedIOSVersion! >= version;
  }

  /// Verifica si la versión de iOS está entre dos niveles
  static Future<bool> isBetween(double minVersion, double maxVersion) async {
    if (!isIOS) return false;
    final version = await getIOSVersion();
    return version >= minVersion && version <= maxVersion;
  }

  /// Verifica si el dispositivo es un iPhone
  static Future<bool> get isIPhone async {
    if (!isIOS) return false;
    final deviceInfo = await getDeviceInfo();
    return deviceInfo['isIPhone'] as bool? ?? false;
  }

  /// Verifica si el dispositivo es un iPad
  static Future<bool> get isIPad async {
    if (!isIOS) return false;
    final deviceInfo = await getDeviceInfo();
    return deviceInfo['isIPad'] as bool? ?? false;
  }

  /// Características disponibles por versión de iOS

  /// iOS 13+ (2019): Dark Mode, Sign in with Apple
  static Future<bool> get supportsDarkMode async =>
      isIOS && await isAtLeast(iOS13);

  /// iOS 13+ (2019): Sign in with Apple
  static Future<bool> get supportsSignInWithApple async =>
      isIOS && await isAtLeast(iOS13);

  /// iOS 13+ (2019): SF Symbols
  static Future<bool> get supportsSFSymbols async =>
      isIOS && await isAtLeast(iOS13);

  /// iOS 14+ (2020): Widgets
  static Future<bool> get supportsWidgets async =>
      isIOS && await isAtLeast(iOS14);

  /// iOS 14+ (2020): App Clips
  static Future<bool> get supportsAppClips async =>
      isIOS && await isAtLeast(iOS14);

  /// iOS 14+ (2020): App Library
  static Future<bool> get supportsAppLibrary async =>
      isIOS && await isAtLeast(iOS14);

  /// iOS 14+ (2020): Approximate Location
  static Future<bool> get supportsApproximateLocation async =>
      isIOS && await isAtLeast(iOS14);

  /// iOS 15+ (2021): Focus Modes
  static Future<bool> get supportsFocusModes async =>
      isIOS && await isAtLeast(iOS15);

  /// iOS 15+ (2021): Live Text
  static Future<bool> get supportsLiveText async =>
      isIOS && await isAtLeast(iOS15);

  /// iOS 15+ (2021): SharePlay
  static Future<bool> get supportsSharePlay async =>
      isIOS && await isAtLeast(iOS15);

  /// iOS 15+ (2021): Async/Await en Swift
  static Future<bool> get supportsAsyncAwait async =>
      isIOS && await isAtLeast(iOS15);

  /// iOS 16+ (2022): Lock Screen Widgets
  static Future<bool> get supportsLockScreenWidgets async =>
      isIOS && await isAtLeast(iOS16);

  /// iOS 16+ (2022): Live Activities
  static Future<bool> get supportsLiveActivities async =>
      isIOS && await isAtLeast(iOS16);

  /// iOS 16+ (2023): WeatherKit
  static Future<bool> get supportsWeatherKit async =>
      isIOS && await isAtLeast(iOS16);

  /// iOS 17+ (2023): Interactive Widgets
  static Future<bool> get supportsInteractiveWidgets async =>
      isIOS && await isAtLeast(iOS17);

  /// iOS 17+ (2023): StandBy Mode
  static Future<bool> get supportsStandByMode async =>
      isIOS && await isAtLeast(iOS17);

  /// iOS 17+ (2023): App Intents
  static Future<bool> get supportsAppIntents async =>
      isIOS && await isAtLeast(iOS17);

  /// Información de compatibilidad
  static Future<String> getCompatibilityInfo() async {
    if (!isIOS) {
      return 'No es una plataforma iOS';
    }

    final version = await getIOSVersion();
    final versionName = await getIOSVersionName();
    final deviceInfo = await getDeviceInfo();
    final deviceType = deviceInfo['model'] ?? 'Unknown';

    return '''
Información de Compatibilidad iOS:
- Versión mínima soportada: iOS ${minSupportedVersion.toStringAsFixed(1)}
- Versión objetivo: iOS 17+
- Cobertura estimada: 95% de dispositivos iOS activos
- Plataforma actual: iOS $versionName (${version.toStringAsFixed(1)})
- Dispositivo: $deviceType
- Tipo: ${deviceInfo['isIPhone'] == true ? 'iPhone' : deviceInfo['isIPad'] == true ? 'iPad' : 'Unknown'}
    '''.trim();
  }

  /// Fallback para funcionalidades no disponibles
  static Future<T> withFallback<T>({
    required Future<bool> condition,
    required T Function() onSupported,
    required T Function() onUnsupported,
  }) async {
    final isSupported = await condition;
    return isSupported ? onSupported() : onUnsupported();
  }

  /// Ejecuta una acción solo si la versión es compatible
  static Future<void> executeIfSupported({
    required Future<bool> condition,
    required void Function() action,
    void Function()? fallback,
  }) async {
    final isSupported = await condition;
    if (isSupported) {
      action();
    } else if (fallback != null) {
      fallback();
    }
  }

  /// Inicializa el cache de versión (debe llamarse al inicio de la app)
  static Future<void> initialize() async {
    if (isIOS) {
      await getIOSVersion();
      await getDeviceInfo();
    }
  }

  /// Limpia el cache
  static void clearCache() {
    _cachedIOSVersion = null;
    _cachedDeviceInfo = null;
  }

  /// Verifica si el dispositivo soporta iPhone 6s o posterior
  /// (Todos los dispositivos con iOS 13+ lo hacen)
  static Future<bool> get supportsModernDevices async {
    return isIOS && await isAtLeast(minSupportedVersion);
  }
}

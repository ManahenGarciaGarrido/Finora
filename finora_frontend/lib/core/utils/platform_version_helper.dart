import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Utilidad para manejar características específicas de versión de Android
/// con fallbacks para funcionalidades no disponibles en versiones antiguas.
///
/// Esta clase proporciona métodos para verificar la versión de Android
/// y habilitar/deshabilitar características según la compatibilidad.
class PlatformVersionHelper {
  static const MethodChannel _channel =
      MethodChannel('com.finora.app/platform_version');
  /// Versión mínima soportada: Android 8.0 Oreo (API 26)
  static const int minSupportedApiLevel = 26;

  /// Android 8.0 Oreo (API 26)
  static const int androidOreo = 26;

  /// Android 8.1 Oreo (API 27)
  static const int androidOreoMR1 = 27;

  /// Android 9 Pie (API 28)
  static const int androidPie = 28;

  /// Android 10 (API 29)
  static const int androidQ = 29;

  /// Android 11 (API 30)
  static const int androidR = 30;

  /// Android 12 (API 31)
  static const int androidS = 31;

  /// Android 12L (API 32)
  static const int androidSV2 = 32;

  /// Android 13 (API 33)
  static const int androidTiramisu = 33;

  /// Android 14 (API 34)
  static const int androidUpsideDownCake = 34;

  /// Cache de la versión de Android
  static int? _cachedAndroidVersion;

  /// Cache de información del dispositivo
  static Map<String, dynamic>? _cachedDeviceInfo;

  /// Verifica si la plataforma actual es Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Obtiene la versión de Android actual (API Level)
  /// Retorna 0 si no es Android o si no se puede determinar
  static Future<int> getAndroidVersion() async {
    if (!isAndroid) return 0;

    // Usar cache si está disponible
    if (_cachedAndroidVersion != null) {
      return _cachedAndroidVersion!;
    }

    try {
      final int version = await _channel.invokeMethod('getAndroidVersion');
      _cachedAndroidVersion = version;
      return version;
    } catch (e) {
      debugPrint('Error obteniendo versión de Android: $e');
      // Si falla, asumimos la versión mínima soportada
      return minSupportedApiLevel;
    }
  }

  /// Obtiene el nombre de la versión de Android (e.g., "8.0.0")
  static Future<String> getAndroidVersionName() async {
    if (!isAndroid) return 'N/A';

    try {
      final String versionName =
          await _channel.invokeMethod('getAndroidVersionName');
      return versionName;
    } catch (e) {
      debugPrint('Error obteniendo nombre de versión de Android: $e');
      return 'Unknown';
    }
  }

  /// Obtiene información completa del dispositivo
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    if (!isAndroid) {
      return {
        'platform': 'non-android',
        'apiLevel': 0,
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
      debugPrint('Error obteniendo información del dispositivo: $e');
      return {
        'platform': 'android',
        'apiLevel': minSupportedApiLevel,
        'error': e.toString(),
      };
    }
  }

  /// Verifica si la versión de Android es al menos la especificada
  static Future<bool> isAtLeast(int apiLevel) async {
    if (!isAndroid) return false;

    try {
      final bool result = await _channel.invokeMethod(
        'isAtLeastVersion',
        {'version': apiLevel},
      );
      return result;
    } catch (e) {
      debugPrint('Error verificando versión de Android: $e');
      // Fallback: usar el método de obtener versión
      final version = await getAndroidVersion();
      return version >= apiLevel;
    }
  }

  /// Versión sincrónica de isAtLeast (usa cache)
  /// IMPORTANTE: Debe llamarse getAndroidVersion() primero para popular el cache
  static bool isAtLeastSync(int apiLevel) {
    if (!isAndroid) return false;
    if (_cachedAndroidVersion == null) {
      debugPrint(
          'Advertencia: Cache de versión no inicializado. Llama getAndroidVersion() primero.');
      // Asumimos que cumple con la versión mínima
      return apiLevel >= minSupportedApiLevel;
    }
    return _cachedAndroidVersion! >= apiLevel;
  }

  /// Verifica si la versión de Android está entre dos niveles
  static Future<bool> isBetween(int minApiLevel, int maxApiLevel) async {
    if (!isAndroid) return false;
    final version = await getAndroidVersion();
    return version >= minApiLevel && version <= maxApiLevel;
  }

  /// Características disponibles por versión de Android

  /// Android 8.0+ (API 26): Canales de notificación
  static Future<bool> get supportsNotificationChannels async =>
      isAndroid && await isAtLeast(androidOreo);

  /// Android 8.0+ (API 26): Fuentes en XML
  static Future<bool> get supportsFontsInXml async =>
      isAndroid && await isAtLeast(androidOreo);

  /// Android 8.0+ (API 26): Autofill Framework
  static Future<bool> get supportsAutofill async =>
      isAndroid && await isAtLeast(androidOreo);

  /// Android 8.1+ (API 27): Neural Networks API
  static Future<bool> get supportsNeuralNetworks async =>
      isAndroid && await isAtLeast(androidOreoMR1);

  /// Android 9+ (API 28): Display Cutout (notch)
  static Future<bool> get supportsDisplayCutout async =>
      isAndroid && await isAtLeast(androidPie);

  /// Android 9+ (API 28): Multi-camera API
  static Future<bool> get supportsMultiCamera async =>
      isAndroid && await isAtLeast(androidPie);

  /// Android 10+ (API 29): Scoped Storage
  static Future<bool> get requiresScopedStorage async =>
      isAndroid && await isAtLeast(androidQ);

  /// Android 10+ (API 29): Dark Theme
  static Future<bool> get supportsDarkTheme async =>
      isAndroid && await isAtLeast(androidQ);

  /// Android 10+ (API 29): Gestural Navigation
  static Future<bool> get supportsGesturalNavigation async =>
      isAndroid && await isAtLeast(androidQ);

  /// Android 11+ (API 30): Storage Access Framework
  static Future<bool> get requiresStorageAccessFramework async =>
      isAndroid && await isAtLeast(androidR);

  /// Android 11+ (API 30): One-time Permissions
  static Future<bool> get supportsOneTimePermissions async =>
      isAndroid && await isAtLeast(androidR);

  /// Android 12+ (API 31): Material You
  static Future<bool> get supportsMaterialYou async =>
      isAndroid && await isAtLeast(androidS);

  /// Android 12+ (API 31): Splash Screen API
  static Future<bool> get supportsSplashScreenApi async =>
      isAndroid && await isAtLeast(androidS);

  /// Android 13+ (API 33): Predictive Back Gesture
  static Future<bool> get supportsPredictiveBack async =>
      isAndroid && await isAtLeast(androidTiramisu);

  /// Android 13+ (API 33): Per-app Language Preferences
  static Future<bool> get supportsPerAppLanguage async =>
      isAndroid && await isAtLeast(androidTiramisu);

  /// Android 13+ (API 33): Notification Runtime Permission
  static Future<bool> get requiresNotificationPermission async =>
      isAndroid && await isAtLeast(androidTiramisu);

  /// Android 14+ (API 34): Gramática y ortografía mejoradas
  static Future<bool> get supportsEnhancedGrammar async =>
      isAndroid && await isAtLeast(androidUpsideDownCake);

  /// Información de compatibilidad
  static Future<String> getCompatibilityInfo() async {
    if (!isAndroid) {
      return 'No es una plataforma Android';
    }

    final version = await getAndroidVersion();
    final versionName = await getAndroidVersionName();

    return '''
Información de Compatibilidad:
- Versión mínima soportada: Android 8.0 (API $minSupportedApiLevel)
- Versión objetivo: Android 14 (API 34)
- Cobertura estimada: 95% de dispositivos Android activos
- Plataforma actual: Android $versionName (API $version)
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
    if (isAndroid) {
      await getAndroidVersion();
      await getDeviceInfo();
    }
  }

  /// Limpia el cache
  static void clearCache() {
    _cachedAndroidVersion = null;
    _cachedDeviceInfo = null;
  }
}

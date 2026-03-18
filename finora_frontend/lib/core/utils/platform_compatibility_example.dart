import 'package:flutter/material.dart';
import 'platform_version_helper.dart';

/// Ejemplo de uso de PlatformVersionHelper para manejar
/// características específicas de versión con fallbacks
class PlatformCompatibilityExample {
  /// Ejemplo 1: Usar canales de notificación con fallback
  Future<void> showNotificationWithFallback() async {
    if (await PlatformVersionHelper.supportsNotificationChannels) {
      // Android 8.0+: Usar canales de notificación
      debugPrint('Usando canales de notificación (Android 8.0+)');
      // Implementar notificación con canales
    } else {
      // Android < 8.0: Usar notificaciones tradicionales
      debugPrint('Usando notificaciones tradicionales (Android < 8.0)');
      // Implementar notificación tradicional
    }
  }

  /// Ejemplo 2: Usar withFallback para seleccionar implementación
  Future<Widget> getStorageWidget() async {
    return await PlatformVersionHelper.withFallback(
      condition: PlatformVersionHelper.requiresScopedStorage,
      onSupported: () {
        // Android 10+: Usar Scoped Storage
        debugPrint('Usando Scoped Storage (Android 10+)');
        return const Text('Scoped Storage habilitado');
      },
      onUnsupported: () {
        // Android < 10: Usar almacenamiento tradicional
        debugPrint('Usando almacenamiento tradicional (Android < 10)');
        return const Text('Almacenamiento tradicional');
      },
    );
  }

  /// Ejemplo 3: Ejecutar acción solo si se soporta
  Future<void> setupMaterialYouTheme() async {
    await PlatformVersionHelper.executeIfSupported(
      condition: PlatformVersionHelper.supportsMaterialYou,
      action: () {
        // Android 12+: Configurar Material You
        debugPrint('Configurando Material You (Android 12+)');
        // Implementar tema Material You
      },
      fallback: () {
        // Android < 12: Usar tema tradicional
        debugPrint('Usando tema Material tradicional (Android < 12)');
        // Implementar tema tradicional
      },
    );
  }

  /// Ejemplo 4: Verificar versión específica
  Future<void> checkAndroidVersion() async {
    final version = await PlatformVersionHelper.getAndroidVersion();
    final versionName = await PlatformVersionHelper.getAndroidVersionName();

    debugPrint('Android API Level: $version');
    debugPrint('Android Version: $versionName');

    if (await PlatformVersionHelper.isAtLeast(
        PlatformVersionHelper.androidTiramisu)) {
      debugPrint('Android 13+ detectado - Solicitando permiso de notificaciones');
      // Solicitar permiso de notificaciones en Android 13+
    }
  }

  /// Ejemplo 5: Obtener información completa del dispositivo
  Future<void> logDeviceInfo() async {
    final deviceInfo = await PlatformVersionHelper.getDeviceInfo();

    debugPrint('Información del dispositivo:');
    debugPrint('- Fabricante: ${deviceInfo['manufacturer']}');
    debugPrint('- Modelo: ${deviceInfo['model']}');
    debugPrint('- Marca: ${deviceInfo['brand']}');
    debugPrint('- API Level: ${deviceInfo['apiLevel']}');
    debugPrint('- Versión: ${deviceInfo['versionName']}');
  }

  /// Ejemplo 6: Manejo de permisos según versión
  Future<void> requestStoragePermission() async {
    if (await PlatformVersionHelper.requiresStorageAccessFramework) {
      // Android 11+: Usar Storage Access Framework
      debugPrint('Solicitando acceso mediante Storage Access Framework');
      // Implementar SAF
    } else if (await PlatformVersionHelper.requiresScopedStorage) {
      // Android 10: Usar Scoped Storage
      debugPrint('Usando Scoped Storage');
      // Implementar Scoped Storage
    } else {
      // Android < 10: Solicitar permisos tradicionales
      debugPrint('Solicitando permisos de almacenamiento tradicionales');
      // Solicitar READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE
    }
  }

  /// Ejemplo 7: Configuración de UI según capacidades
  Future<Widget> buildAdaptiveUI() async {
    // Verificar soporte de Display Cutout (notch)
    final hasDisplayCutout =
        await PlatformVersionHelper.supportsDisplayCutout;

    // Verificar soporte de navegación gestual
    final hasGesturalNav =
        await PlatformVersionHelper.supportsGesturalNavigation;

    return Column(
      children: [
        if (hasDisplayCutout)
          const Padding(
            padding: EdgeInsets.only(top: 32.0),
            child: Text('UI adaptada para notch'),
          )
        else
          const Text('UI estándar'),
        if (hasGesturalNav)
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text('Navegación gestual habilitada'),
          ),
      ],
    );
  }

  /// Ejemplo 8: Inicialización en el arranque de la app
  static Future<void> initializePlatformCompatibility() async {
    // Inicializar cache de versión
    await PlatformVersionHelper.initialize();

    // Mostrar información de compatibilidad
    final compatInfo = await PlatformVersionHelper.getCompatibilityInfo();
    debugPrint(compatInfo);

    // Verificar que la versión mínima se cumple
    if (PlatformVersionHelper.isAndroid) {
      final version = await PlatformVersionHelper.getAndroidVersion();
      if (version < PlatformVersionHelper.minSupportedApiLevel) {
        debugPrint(
            'ADVERTENCIA: La versión de Android ($version) es menor que la mínima soportada (${PlatformVersionHelper.minSupportedApiLevel})');
        // Mostrar diálogo al usuario informándole que actualice
      }
    }
  }
}

/// Widget de demostración de compatibilidad
class CompatibilityDemoWidget extends StatefulWidget {
  const CompatibilityDemoWidget({super.key});

  @override
  State<CompatibilityDemoWidget> createState() =>
      _CompatibilityDemoWidgetState();
}

class _CompatibilityDemoWidgetState extends State<CompatibilityDemoWidget> {
  String _compatibilityInfo = 'Cargando...';
  Map<String, dynamic> _deviceInfo = {};

  @override
  void initState() {
    super.initState();
    _loadCompatibilityInfo();
  }

  Future<void> _loadCompatibilityInfo() async {
    final info = await PlatformVersionHelper.getCompatibilityInfo();
    final deviceInfo = await PlatformVersionHelper.getDeviceInfo();

    setState(() {
      _compatibilityInfo = info;
      _deviceInfo = deviceInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información de Compatibilidad'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _compatibilityInfo,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Información del Dispositivo:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._deviceInfo.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('${entry.key}: ${entry.value}'),
              );
            }),
            const SizedBox(height: 24),
            const Text(
              'Características Soportadas:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<String>>(
              future: _getFeaturesList(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: snapshot.data!
                      .map((feature) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                const Icon(Icons.check, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(feature),
                              ],
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _getFeaturesList() async {
    final features = <String>[];

    if (await PlatformVersionHelper.supportsNotificationChannels) {
      features.add('Canales de Notificación (API 26+)');
    }
    if (await PlatformVersionHelper.supportsAutofill) {
      features.add('Autofill Framework (API 26+)');
    }
    if (await PlatformVersionHelper.supportsDisplayCutout) {
      features.add('Display Cutout / Notch (API 28+)');
    }
    if (await PlatformVersionHelper.supportsDarkTheme) {
      features.add('Tema Oscuro (API 29+)');
    }
    if (await PlatformVersionHelper.requiresScopedStorage) {
      features.add('Scoped Storage (API 29+)');
    }
    if (await PlatformVersionHelper.supportsOneTimePermissions) {
      features.add('Permisos de Una Vez (API 30+)');
    }
    if (await PlatformVersionHelper.supportsMaterialYou) {
      features.add('Material You (API 31+)');
    }
    if (await PlatformVersionHelper.supportsPredictiveBack) {
      features.add('Gesto Predictivo de Retroceso (API 33+)');
    }
    if (await PlatformVersionHelper.requiresNotificationPermission) {
      features.add('Permiso de Notificaciones en Runtime (API 33+)');
    }

    return features;
  }
}

import 'package:flutter/material.dart';
import 'ios_version_helper.dart';

/// Ejemplo de uso de IOSVersionHelper para manejar
/// características específicas de versión con fallbacks
class IOSCompatibilityExample {
  /// Ejemplo 1: Usar Dark Mode con fallback
  Future<void> setupThemeWithFallback() async {
    if (await IOSVersionHelper.supportsDarkMode) {
      // iOS 13+: Usar Dark Mode nativo
      debugPrint('Usando Dark Mode nativo (iOS 13+)');
      // Implementar dark mode
    } else {
      // iOS < 13: Usar tema manual
      debugPrint('Usando tema manual (iOS < 13)');
      // Implementar tema manual
    }
  }

  /// Ejemplo 2: Usar withFallback para seleccionar implementación
  Future<Widget> getLocationWidget() async {
    return await IOSVersionHelper.withFallback(
      condition: IOSVersionHelper.supportsApproximateLocation,
      onSupported: () {
        // iOS 14+: Ofrecer ubicación aproximada
        debugPrint('Ofreciendo ubicación aproximada (iOS 14+)');
        return const Text('Ubicación aproximada disponible');
      },
      onUnsupported: () {
        // iOS < 14: Solo ubicación precisa
        debugPrint('Solo ubicación precisa (iOS < 14)');
        return const Text('Solo ubicación precisa');
      },
    );
  }

  /// Ejemplo 3: Ejecutar acción solo si se soporta
  Future<void> setupWidgets() async {
    await IOSVersionHelper.executeIfSupported(
      condition: IOSVersionHelper.supportsWidgets,
      action: () {
        // iOS 14+: Configurar widgets
        debugPrint('Configurando widgets (iOS 14+)');
        // Implementar widgets
      },
      fallback: () {
        // iOS < 14: Sin widgets
        debugPrint('Widgets no disponibles (iOS < 14)');
      },
    );
  }

  /// Ejemplo 4: Verificar versión específica
  Future<void> checkIOSVersion() async {
    final version = await IOSVersionHelper.getIOSVersion();
    final versionName = await IOSVersionHelper.getIOSVersionName();

    debugPrint('iOS Version: $versionName');
    debugPrint('iOS Version Number: $version');

    if (await IOSVersionHelper.isAtLeast(IOSVersionHelper.iOS17)) {
      debugPrint('iOS 17+ detectado - Habilitando Interactive Widgets');
      // Habilitar interactive widgets
    }
  }

  /// Ejemplo 5: Obtener información completa del dispositivo
  Future<void> logDeviceInfo() async {
    final deviceInfo = await IOSVersionHelper.getDeviceInfo();

    debugPrint('Información del dispositivo iOS:');
    debugPrint('- Sistema: ${deviceInfo['systemName']}');
    debugPrint('- Versión: ${deviceInfo['systemVersion']}');
    debugPrint('- Modelo: ${deviceInfo['model']}');
    debugPrint('- Nombre: ${deviceInfo['name']}');
    debugPrint('- Es iPhone: ${deviceInfo['isIPhone']}');
    debugPrint('- Es iPad: ${deviceInfo['isIPad']}');
  }

  /// Ejemplo 6: Manejo de características según versión
  Future<void> setupFeatures() async {
    if (await IOSVersionHelper.supportsLiveActivities) {
      // iOS 16+: Usar Live Activities
      debugPrint('Configurando Live Activities');
      // Implementar Live Activities
    }

    if (await IOSVersionHelper.supportsLiveText) {
      // iOS 15+: Habilitar Live Text
      debugPrint('Habilitando Live Text');
      // Implementar Live Text
    }

    if (await IOSVersionHelper.supportsSFSymbols) {
      // iOS 13+: Usar SF Symbols
      debugPrint('Usando SF Symbols');
      // Usar SF Symbols
    }
  }

  /// Ejemplo 7: Configuración de UI según capacidades
  Future<Widget> buildAdaptiveUI() async {
    // Verificar soporte de widgets
    final hasWidgets = await IOSVersionHelper.supportsWidgets;

    // Verificar tipo de dispositivo
    final isIPad = await IOSVersionHelper.isIPad;
    final isIPhone = await IOSVersionHelper.isIPhone;

    return Column(
      children: [
        if (hasWidgets)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Widgets habilitados (iOS 14+)'),
          ),
        if (isIPad)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('UI optimizada para iPad'),
          )
        else if (isIPhone)
          const Text('UI optimizada para iPhone'),
      ],
    );
  }

  /// Ejemplo 8: Inicialización en el arranque de la app
  static Future<void> initializeIOSCompatibility() async {
    // Inicializar cache de versión
    await IOSVersionHelper.initialize();

    // Mostrar información de compatibilidad
    final compatInfo = await IOSVersionHelper.getCompatibilityInfo();
    debugPrint(compatInfo);

    // Verificar que la versión mínima se cumple
    if (IOSVersionHelper.isIOS) {
      final version = await IOSVersionHelper.getIOSVersion();
      if (version < IOSVersionHelper.minSupportedVersion) {
        debugPrint(
            'ADVERTENCIA: La versión de iOS ($version) es menor que la mínima soportada (${IOSVersionHelper.minSupportedVersion})');
        // Mostrar diálogo al usuario informándole que actualice
      }
    }
  }
}

/// Widget de demostración de compatibilidad iOS
class IOSCompatibilityDemoWidget extends StatefulWidget {
  const IOSCompatibilityDemoWidget({super.key});

  @override
  State<IOSCompatibilityDemoWidget> createState() =>
      _IOSCompatibilityDemoWidgetState();
}

class _IOSCompatibilityDemoWidgetState
    extends State<IOSCompatibilityDemoWidget> {
  String _compatibilityInfo = 'Cargando...';
  Map<String, dynamic> _deviceInfo = {};

  @override
  void initState() {
    super.initState();
    _loadCompatibilityInfo();
  }

  Future<void> _loadCompatibilityInfo() async {
    final info = await IOSVersionHelper.getCompatibilityInfo();
    final deviceInfo = await IOSVersionHelper.getDeviceInfo();

    setState(() {
      _compatibilityInfo = info;
      _deviceInfo = deviceInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información de Compatibilidad iOS'),
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
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(child: Text(feature)),
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

    if (await IOSVersionHelper.supportsDarkMode) {
      features.add('Dark Mode (iOS 13+)');
    }
    if (await IOSVersionHelper.supportsSignInWithApple) {
      features.add('Sign in with Apple (iOS 13+)');
    }
    if (await IOSVersionHelper.supportsSFSymbols) {
      features.add('SF Symbols (iOS 13+)');
    }
    if (await IOSVersionHelper.supportsWidgets) {
      features.add('Home Screen Widgets (iOS 14+)');
    }
    if (await IOSVersionHelper.supportsAppClips) {
      features.add('App Clips (iOS 14+)');
    }
    if (await IOSVersionHelper.supportsApproximateLocation) {
      features.add('Ubicación Aproximada (iOS 14+)');
    }
    if (await IOSVersionHelper.supportsFocusModes) {
      features.add('Focus Modes (iOS 15+)');
    }
    if (await IOSVersionHelper.supportsLiveText) {
      features.add('Live Text (iOS 15+)');
    }
    if (await IOSVersionHelper.supportsSharePlay) {
      features.add('SharePlay (iOS 15+)');
    }
    if (await IOSVersionHelper.supportsLockScreenWidgets) {
      features.add('Lock Screen Widgets (iOS 16+)');
    }
    if (await IOSVersionHelper.supportsLiveActivities) {
      features.add('Live Activities (iOS 16+)');
    }
    if (await IOSVersionHelper.supportsInteractiveWidgets) {
      features.add('Interactive Widgets (iOS 17+)');
    }
    if (await IOSVersionHelper.supportsStandByMode) {
      features.add('StandBy Mode (iOS 17+)');
    }

    return features;
  }
}

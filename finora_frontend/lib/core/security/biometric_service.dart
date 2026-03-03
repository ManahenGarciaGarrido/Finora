import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

/// RF-03 / HU-02: Servicio de Autenticación Biométrica
///
/// Gestiona la autenticación biométrica (Touch ID, Face UD, huella Android)
/// usando el paquete local_auth. Almacena el flag de habilitación en
/// flutter_secure_storage (Keychain en iOS, KeyStore en Android).
///
/// Criterios de aceptación cubiertos:
/// - Activación opcional en configuración de usuario
/// - Soporte Touch ID (iOS), Face ID (iOS), huella digital (Android)
/// - Fallback a contraseña si falla biometría
/// - Acceso en menos de 2 segundos
/// - Almacenamiento seguro de credenciales biométricas

/// Resultado de la autenticación biométrica
enum BiometricResult {
  /// Autenticación exitosa
  success,

  /// No disponible en el dispositivo
  notAvailable,

  /// No configurada en el dispositivo
  notEnrolled,

  /// El usuario canceló la operación
  canceled,

  /// Error durante la autenticación
  error,

  /// Biometría deshabilitada por el usuario en la app
  disabled,
}

/// Tipos de biometría disponibles en el dispositivo
enum BiometricCapability { fingerprint, feceId, iris, none }

class BiometricService {
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  BiometricService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  }) : _localAuth = localAuth ?? LocalAuthentication(),
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
           );

  // ── Disponibilidad ─────────────────────────────────────────────────────────

  /// Devuelve true si el dispositivo tiene biometría disponible y configurada
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Lista los tipos de biometría enrollados en el dispositivo
  Future<List<BiometricCapability>> getAvailableBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      final result = <BiometricCapability>[];
      for (final type in biometrics) {
        switch (type) {
          case BiometricType.fingerprint:
            result.add(BiometricCapability.fingerprint);
          case BiometricType.face:
            result.add(BiometricCapability.feceId);
          case BiometricType.iris:
            result.add(BiometricCapability.iris);
          case BiometricType.strong:
          case BiometricType.weak:
            if (!result.contains(BiometricCapability.fingerprint)) {
              result.add(BiometricCapability.fingerprint);
            }
        }
      }
      if (result.isEmpty) result.add(BiometricCapability.none);
      return result;
    } on PlatformException {
      return [BiometricCapability.none];
    }
  }

  /// Descripción amigable del tipo de biometría principal disponible
  Future<String> getBiometricLabel() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.contains(BiometricCapability.feceId)) {
      return 'Face ID';
    }
    if (biometrics.contains(BiometricCapability.fingerprint)) {
      return 'Huella Digital';
    }
    return 'Biometría';
  }

  // ── Preferencias del usuario ────────────────────────────────────────────────

  /// Devuelve true si el usuario ha habilitado la biometría en la app
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(
        key: StorageKeys.biometricEnabled,
      );
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Habilita o deshabilita la autenticación biométrica
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: StorageKeys.biometricEnabled,
      value: enabled.toString(),
    );
  }

  // ── Autenticación ─────────────────────────────────────────────────────────

  /// Autentica al usuario con biometría.
  ///
  /// Retorna [BiometricResult.success] si se autenticó correctamente.
  /// Retorna [BiometricResult.disabled] si el usuario no ha habilitado la biometría.
  /// Retorna [BiometricResult.notAvailable] si el dispositivo no la soporta.
  /// Retorna [BiometricResult.cancelled] si el usuario canceló.
  Future<BiometricResult> authenticate({
    String reason = 'Confirma tu identidad para acceder a Finora',
  }) async {
    // Verifica que el usuario la ha ahbilitado
    final enabled = await isBiometricEnabled();
    if (!enabled) return BiometricResult.disabled;

    // Verifica disponibilidad del dispositivo
    final avaiable = await isAvailable();
    if (!avaiable) return BiometricResult.notAvailable;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true, // Manteber diálogo al salir y volver
          biometricOnly: false, // Permitir PIN como fallback
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      return authenticated ? BiometricResult.success : BiometricResult.canceled;
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        return BiometricResult.notEnrolled;
      }
      if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return BiometricResult.error;
      }
      // El usuario canceló con el botón nativo
      return BiometricResult.canceled;
    } catch (_) {
      return BiometricResult.error;
    }
  }

  /// Intenta activar la biometría pidiendo autenticación primero.
  ///
  /// Sólo activa si la autenticación es exitosa (seguridad de activación).
  Future<BiometricResult> enableBiometric() async {
    final available = await isAvailable();
    print('[BIO] isAvailable: $available');
    if (!available) return BiometricResult.notAvailable;

    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      print('[BIO] Enrolled biometrics: $biometrics');

      final authenticated = await _localAuth.authenticate(
        localizedReason:
            'Confirma tu identidad para activar el acceso biométrico',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );
      print('[BIO] authenticated result: $authenticated');

      if (authenticated) {
        await setBiometricEnabled(true);
        return BiometricResult.success;
      }
      return BiometricResult.canceled;
    } on PlatformException catch (e) {
      print('[BIO] PlatformException → code: ${e.code}, msg: ${e.message}');
      if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return BiometricResult.error;
      }
      return BiometricResult.canceled;
    } catch (e) {
      print('[BIO] Error inesperado: $e');
      return BiometricResult.error;
    }
  }

  /// Deshabilita la biometría (no requiere autenticación extra)
  Future<void> disableBiometric() async {
    await setBiometricEnabled(false);
  }

  /// Cancela cualquier operación biométrica en curso
  Future<void> cancelAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (_) {}
  }
}

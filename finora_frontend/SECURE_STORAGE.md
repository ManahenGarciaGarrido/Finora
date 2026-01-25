# Almacenamiento Seguro con Cifrado AES-256

## 📋 Descripción

Implementación de almacenamiento seguro con cifrado AES-256-GCM para proteger tokens de acceso, contraseñas y datos sensibles del usuario en la aplicación Finora.

## ✅ Características Implementadas

### 1. Cifrado AES-256-GCM
- ✅ Algoritmo de cifrado: AES-256 en modo GCM (Galois/Counter Mode)
- ✅ Longitud de clave: 256 bits (32 bytes)
- ✅ IV (Initialization Vector) único por operación (16 bytes)
- ✅ Autenticación de datos integrada (GCM mode)

### 2. Almacenamiento Seguro Nativo
- ✅ **Android**: KeyStore + EncryptedSharedPreferences
- ✅ **iOS**: Keychain con `KeychainAccessibility.first_unlock_this_device`
- ✅ Integración con flutter_secure_storage

### 3. Gestión de Claves
- ✅ Generación de claves maestras aleatorias
- ✅ Almacenamiento seguro de claves en Keychain/KeyStore
- ✅ Soporte para rotación de claves
- ✅ Versionado de claves para compatibilidad

### 4. Protección de Datos Sensibles
- ✅ Tokens de acceso cifrados
- ✅ Datos de usuario cifrados
- ✅ Credenciales bancarias cifradas
- ✅ Ningún dato sensible en texto plano

### 5. Hashing de Contraseñas
- ✅ SHA-256 con salt único por usuario
- ✅ PBKDF2-like (100,000 iteraciones)
- ✅ Formato: `salt:hash` en base64

### 6. Eliminación Segura
- ✅ Sobrescritura de datos antes de eliminar
- ✅ Eliminación de claves de cifrado
- ✅ Limpieza completa al borrar cuenta

## 🏗️ Arquitectura

### Componentes Principales

```
┌─────────────────────────────────────────────────────┐
│              Application Layer                       │
│  (Auth DataSource, Bank DataSource, etc.)           │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│         SecureStorageService                         │
│  - write(key, value, encrypt=true)                   │
│  - read(key, decrypt=true)                           │
│  - delete(key)                                       │
│  - rotateEncryptionKey()                             │
│  - secureDeleteAll()                                 │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│         EncryptionService                            │
│  - encrypt(plainText) → cipherText                   │
│  - decrypt(cipherText) → plainText                   │
│  - hashPassword(password) → hash                     │
│  - verifyPassword(password, hash) → bool             │
│  - rotateKey()                                       │
│  - secureDelete()                                    │
└────────────────────┬────────────────────────────────┘
                     │
       ┌─────────────┴─────────────┐
       │                           │
       ▼                           ▼
┌─────────────────┐    ┌─────────────────────────┐
│  Android        │    │  iOS                     │
│  KeyStore +     │    │  Keychain                │
│  Encrypted      │    │  (Accessibility:         │
│  SharedPrefs    │    │   first_unlock)          │
└─────────────────┘    └─────────────────────────┘
```

### Flujo de Cifrado

```
1. Inicialización
   → Verificar clave maestra
   → Generar si no existe
   → Almacenar en Keychain/KeyStore

2. Escritura de Datos
   → Recibir datos sensibles
   → Generar IV aleatorio
   → Cifrar con AES-256-GCM
   → Empaquetar: {version, iv, data}
   → Codificar en base64
   → Guardar en flutter_secure_storage

3. Lectura de Datos
   → Obtener datos cifrados
   → Decodificar base64
   → Desempaquetar: {version, iv, data}
   → Descifrar con clave maestra
   → Retornar texto plano
```

## 🔧 Uso

### Inicialización

```dart
final secureStorage = SecureStorageService();
await secureStorage.initialize();
```

### Guardar Datos Sensibles

```dart
// Guardar token de acceso
await secureStorage.write(
  key: 'access_token',
  value: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  encrypt: true,
);

// Guardar credenciales bancarias
await secureStorage.write(
  key: 'bank_credentials',
  value: jsonEncode({
    'bank_id': 'bank123',
    'access_token': 'token123',
    'refresh_token': 'refresh123',
  }),
  encrypt: true,
);
```

### Leer Datos Sensibles

```dart
// Leer token de acceso
final token = await secureStorage.read(
  key: 'access_token',
  decrypt: true,
);

// Leer credenciales bancarias
final credentialsJson = await secureStorage.read(
  key: 'bank_credentials',
  decrypt: true,
);
final credentials = jsonDecode(credentialsJson!);
```

### Hash de Contraseñas

```dart
final encryptionService = EncryptionService();
await encryptionService.initialize();

// Hash de contraseña (cliente)
final hashedPassword = await encryptionService.hashPassword('MyPassword123!');
// Resultado: "base64_salt:base64_hash"

// Verificar contraseña
final isValid = await encryptionService.verifyPassword(
  'MyPassword123!',
  hashedPassword,
);
```

### Rotación de Claves

```dart
// Rotar clave de cifrado
await secureStorage.rotateEncryptionKey();

// Todos los datos se re-cifran automáticamente con la nueva clave
```

### Eliminación Segura de Cuenta

```dart
// Al eliminar cuenta de usuario
await secureStorage.secureDeleteAll();

// Esto:
// 1. Sobrescribe datos con datos aleatorios
// 2. Elimina todos los datos
// 3. Elimina claves de cifrado
```

## 🔐 Configuración de Seguridad

### Android

**AndroidManifest.xml** (ya configurado automáticamente por flutter_secure_storage):
```xml
<application
    android:allowBackup="false"
    android:fullBackupContent="false">
    <!-- Deshabilitar backup para prevenir exposición de claves -->
</application>
```

### iOS

**Info.plist** (configuración automática):
- Keychain con `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
- Datos protegidos hasta primer desbloqueo del dispositivo

## 📊 Métricas de Cumplimiento

| Criterio | Estado | Implementación |
|----------|--------|----------------|
| Cifrado AES-256 para tokens | ✅ | `EncryptionService` con AES-256-GCM |
| Cifrado AES-256 para credenciales | ✅ | `SecureStorageService` |
| Uso de Keychain (iOS) | ✅ | flutter_secure_storage + Keychain |
| Uso de KeyStore (Android) | ✅ | flutter_secure_storage + KeyStore |
| Sin datos en texto plano | ✅ | Todos los datos sensibles cifrados |
| Hashing de contraseñas | ✅ | SHA-256 + salt + PBKDF2 |
| Salt único por usuario | ✅ | Generación aleatoria de salt |
| Rotación de claves | ✅ | `rotateEncryptionKey()` |
| Eliminación segura | ✅ | `secureDeleteAll()` con sobrescritura |

## 🧪 Testing

### Ejecutar Tests

```bash
# Tests de cifrado
flutter test test/unit/core/security/encryption_service_test.dart

# Tests de almacenamiento seguro
flutter test test/unit/core/security/secure_storage_service_test.dart

# Todos los tests de seguridad
flutter test test/unit/core/security/
```

### Cobertura de Tests

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 🔍 Verificación y Auditoría

### 1. Inspección de Base de Datos Local

```bash
# Android
adb shell
cd /data/data/com.finora.app/
ls -la
cat shared_prefs/*.xml  # No debe contener datos sensibles en texto plano

# iOS (requiere dispositivo jailbroken para inspección completa)
# Los datos del Keychain no son accesibles sin jailbreak
```

### 2. Análisis de Archivos

**Herramientas:**
- Android: `adb pull` + inspección manual
- iOS: iTunes backup + herramientas de análisis

**Verificación:**
- ✅ Archivos de SharedPreferences no contienen tokens
- ✅ Todos los datos sensibles están en flutter_secure_storage
- ✅ Datos cifrados son ilegibles sin clave

### 3. Pruebas de Extracción

```bash
# Backup de Android
adb backup -f backup.ab com.finora.app
# Extraer y verificar que no hay datos sensibles en texto plano

# Backup de iOS
# Usar iTunes/Finder backup
# Verificar con herramientas como iBackup Viewer
```

### 4. Auditoría de Código

```bash
# Buscar uso de SharedPreferences para datos sensibles
grep -r "SharedPreferences" lib/features/

# Verificar que tokens usan SecureStorageService
grep -r "token" lib/features/authentication/

# Verificar cifrado en datasources
grep -r "encrypt: true" lib/features/
```

## 🚨 Mejores Prácticas

### DO's ✅

1. **Siempre cifrar datos sensibles**
   ```dart
   await secureStorage.write(key: 'token', value: token, encrypt: true);
   ```

2. **Inicializar antes de usar**
   ```dart
   await secureStorage.initialize();
   ```

3. **Usar SecureStorageService para:**
   - Tokens de acceso/refresco
   - Credenciales bancarias
   - Claves API
   - Datos personales identificables (PII)
   - Información financiera

4. **Implementar eliminación segura**
   ```dart
   // Al cerrar sesión
   await authDataSource.clearToken();

   // Al eliminar cuenta
   await authDataSource.secureDeleteAll();
   ```

5. **Rotar claves periódicamente**
   ```dart
   // Cada 90 días o al detectar compromiso
   await secureStorage.rotateEncryptionKey();
   ```

### DON'Ts ❌

1. **NO usar SharedPreferences para datos sensibles**
   ```dart
   // ❌ MAL
   await prefs.setString('token', token);

   // ✅ BIEN
   await secureStorage.write(key: 'token', value: token, encrypt: true);
   ```

2. **NO almacenar contraseñas en texto plano**
   ```dart
   // ❌ MAL - Nunca almacenar contraseñas
   await secureStorage.write(key: 'password', value: password);

   // ✅ BIEN - Solo hash para verificación local
   final hash = await encryptionService.hashPassword(password);
   ```

3. **NO hacer log de datos sensibles**
   ```dart
   // ❌ MAL
   print('Token: $token');

   // ✅ BIEN
   print('Token loaded successfully');
   ```

4. **NO skip encrypt flag para datos sensibles**
   ```dart
   // ❌ MAL
   await secureStorage.write(key: 'token', value: token, encrypt: false);

   // ✅ BIEN
   await secureStorage.write(key: 'token', value: token, encrypt: true);
   ```

## 🔄 Migración de Datos Existentes

Si tienes datos no cifrados en SharedPreferences:

```dart
Future<void> migrateToSecureStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final secureStorage = SecureStorageService();
  await secureStorage.initialize();

  // Migrar token de acceso
  final token = prefs.getString('access_token');
  if (token != null) {
    await secureStorage.write(
      key: 'access_token',
      value: token,
      encrypt: true,
    );
    await prefs.remove('access_token');
  }

  // Migrar otros datos sensibles...
}
```

## 📝 Archivos Relacionados

### Core
- `lib/core/constants/encryption_config.dart` - Configuración de cifrado
- `lib/core/security/encryption_service.dart` - Servicio de cifrado AES-256
- `lib/core/security/secure_storage_service.dart` - Servicio de almacenamiento seguro

### Features
- `lib/features/authentication/data/datasources/auth_local_datasource.dart` - DataSource con cifrado

### Tests
- `test/unit/core/security/encryption_service_test.dart` - Tests de cifrado
- `test/unit/core/security/secure_storage_service_test.dart` - Tests de almacenamiento

### Dependencies
- `pubspec.yaml` - Dependencias: crypto, encrypt, flutter_secure_storage

## 🔧 Troubleshooting

### Error: "Failed to initialize encryption"

**Causa:** No se puede acceder a Keychain/KeyStore

**Solución:**
- Android: Verificar permisos en AndroidManifest
- iOS: Verificar code signing y entitlements
- Reinstalar app en dispositivo

### Error: "Decryption failed"

**Causa:** Clave de cifrado cambió o datos corruptos

**Solución:**
```dart
try {
  final data = await secureStorage.read(key: 'key');
} catch (e) {
  // Re-generar clave y solicitar re-login
  await secureStorage.secureDeleteAll();
  // Redirect to login
}
```

### Error: "Key rotation failed"

**Causa:** Error al re-cifrar datos

**Solución:**
```dart
// Backup manual antes de rotar
final allData = await secureStorage.readAll(decrypt: true);
// Guardar backup temporal
// Intentar rotación nuevamente
```

## 🔐 Consideraciones de Seguridad

### Biometría

Para agregar autenticación biométrica adicional:

```dart
// TODO: Implementar en futuras versiones
final localAuth = LocalAuthentication();
final canAuth = await localAuth.canCheckBiometrics;

if (canAuth) {
  final authenticated = await localAuth.authenticate(
    localizedReason: 'Authenticate to access secure data',
  );

  if (authenticated) {
    final token = await secureStorage.read(key: 'token');
  }
}
```

### Jailbreak/Root Detection

```dart
// TODO: Implementar detección de dispositivos comprometidos
// Rechazar operaciones sensibles en dispositivos rooteados
```

## 📚 Referencias

- [OWASP Mobile Security Testing Guide - Data Storage](https://owasp.org/www-project-mobile-security-testing-guide/)
- [flutter_secure_storage Package](https://pub.dev/packages/flutter_secure_storage)
- [AES-GCM Encryption](https://en.wikipedia.org/wiki/Galois/Counter_Mode)
- [Android KeyStore System](https://developer.android.com/training/articles/keystore)
- [iOS Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [NIST Cryptographic Standards](https://csrc.nist.gov/projects/cryptographic-standards-and-guidelines)

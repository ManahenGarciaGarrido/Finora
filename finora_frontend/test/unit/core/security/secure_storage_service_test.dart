import 'package:finora_frontend/core/security/encryption_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/core/security/secure_storage_service.dart';

// ---------------------------------------------------------------------------
// Fake in-memory FlutterSecureStorage via method channel mock
// ---------------------------------------------------------------------------

final _fakeStorage = <String, String?>{};

void _setupFakeSecureStorage() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall methodCall) async {
          final args = methodCall.arguments as Map?;
          final key = args?['key'] as String?;

          switch (methodCall.method) {
            case 'read':
              return key != null ? _fakeStorage[key] : null;
            case 'write':
              if (key != null) _fakeStorage[key] = args?['value'] as String?;
              return null;
            case 'delete':
              if (key != null) _fakeStorage.remove(key);
              return null;
            case 'readAll':
              return Map<String, String>.fromEntries(
                _fakeStorage.entries
                    .where((e) => e.value != null)
                    .map((e) => MapEntry(e.key, e.value!)),
              );
            case 'deleteAll':
              _fakeStorage.clear();
              return null;
            case 'containsKey':
              return key != null && _fakeStorage.containsKey(key);
            default:
              return null;
          }
        },
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureStorageService', () {
    late SecureStorageService secureStorage;

    setUp(() {
      _fakeStorage.clear();
      _setupFakeSecureStorage();
      secureStorage = SecureStorageService(
        encryptionService: FakeEncryptionService(),
      );
    });

    test('should write and read encrypted data', () async {
      // Arrange
      await secureStorage.initialize();
      const key = 'test_key';
      const value = 'sensitive_data';

      // Act
      await secureStorage.write(key: key, value: value, encrypt: true);
      final result = await secureStorage.read(key: key, decrypt: true);

      // Assert
      expect(result, equals(value));
    });

    test('should return null for non-existent key', () async {
      // Arrange
      await secureStorage.initialize();
      const key = 'non_existent_key';

      // Act
      final result = await secureStorage.read(key: key);

      // Assert
      expect(result, isNull);
    });

    test('should delete data successfully', () async {
      // Arrange
      await secureStorage.initialize();
      const key = 'test_key';
      const value = 'test_value';
      await secureStorage.write(key: key, value: value);

      // Act
      await secureStorage.delete(key: key);
      final result = await secureStorage.read(key: key);

      // Assert
      expect(result, isNull);
    });

    test('should check if key exists', () async {
      // Arrange
      await secureStorage.initialize();
      const key = 'existing_key';
      const value = 'value';
      await secureStorage.write(key: key, value: value);

      // Act
      final exists = await secureStorage.containsKey(key: key);
      final notExists = await secureStorage.containsKey(key: 'non_existent');

      // Assert
      expect(exists, isTrue);
      expect(notExists, isFalse);
    });

    test('should read all data', () async {
      // Arrange
      await secureStorage.initialize();
      await secureStorage.write(key: 'key1', value: 'value1', encrypt: true);
      await secureStorage.write(key: 'key2', value: 'value2', encrypt: true);

      // Act
      final allData = await secureStorage.readAll(decrypt: true);

      // Assert
      expect(allData.length, greaterThanOrEqualTo(2));
      expect(allData['key1'], equals('value1'));
      expect(allData['key2'], equals('value2'));
    });

    test('should delete all data', () async {
      // Arrange
      await secureStorage.initialize();
      await secureStorage.write(key: 'key1', value: 'value1');
      await secureStorage.write(key: 'key2', value: 'value2');

      // Act
      await secureStorage.deleteAll();
      final allData = await secureStorage.readAll();

      // Assert
      expect(allData, isEmpty);
    });

    test('should handle key rotation', () async {
      // Arrange
      await secureStorage.initialize();
      const key = 'test_key';
      const value = 'test_value';
      await secureStorage.write(key: key, value: value, encrypt: true);
      final initialVersion = secureStorage.keyVersion;

      // Act
      await secureStorage.rotateEncryptionKey();
      final result = await secureStorage.read(key: key, decrypt: true);

      // Assert
      expect(result, equals(value)); // Data should still be accessible
      expect(secureStorage.keyVersion, greaterThan(initialVersion));
    });

    test('should securely delete all data', () async {
      // Arrange
      await secureStorage.initialize();
      await secureStorage.write(key: 'sensitive', value: 'data');

      // Act
      await secureStorage.secureDeleteAll();
      final allData = await secureStorage.readAll();

      // Assert
      expect(allData, isEmpty);
    });
  });
}

// ---------------------------------------------------------------------------
// Fake Encryption Service para aislar el test unitario
// ---------------------------------------------------------------------------
class FakeEncryptionService implements EncryptionService {
  int _version = 1;

  @override
  int get keyVersion => _version;

  @override
  Future<void> initialize() async {}

  @override
  Future<String> encrypt(String value) async => 'v$_version:$value';

  @override
  Future<String> decrypt(String value) async {
    // Simulamos desencriptar quitando el prefijo de versión
    if (value.startsWith('v')) {
      return value.substring(value.indexOf(':') + 1);
    }
    return value;
  }

  @override
  Future<void> rotateKey() async {
    _version++;
  }

  @override
  Future<void> secureDelete() async {
    _version = 1;
  }

  @override
  Future<String> hashPassword(String password, {String? providedSalt}) async {
    // Simulamos un hash determinista simple para los tests
    final saltStr = providedSalt != null ? '_$providedSalt' : '';
    return 'fake_hash_$password$saltStr';
  }

  @override
  Future<bool> verifyPassword(String password, String hashedPassword) async {
    // Comprobamos si la contraseña coincide con el patrón de nuestro hash falso
    return hashedPassword.startsWith('fake_hash_$password');
  }
}


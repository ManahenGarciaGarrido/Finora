import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/core/security/encryption_service.dart';
import 'package:finora_frontend/core/errors/exceptions.dart';

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

  group('EncryptionService', () {
    late EncryptionService encryptionService;

    setUp(() {
      _fakeStorage.clear();
      _setupFakeSecureStorage();
      encryptionService = EncryptionService();
    });

    test('should encrypt and decrypt data successfully', () async {
      // Arrange
      await encryptionService.initialize();
      const plainText = 'sensitive_token_12345';

      // Act
      final encrypted = await encryptionService.encrypt(plainText);
      final decrypted = await encryptionService.decrypt(encrypted);

      // Assert
      expect(encrypted, isNot(equals(plainText)));
      expect(decrypted, equals(plainText));
      expect(encrypted.length, greaterThan(plainText.length));
    });

    test('should encrypt different data to different ciphertext', () async {
      // Arrange
      await encryptionService.initialize();
      const plainText1 = 'data1';
      const plainText2 = 'data2';

      // Act
      final encrypted1 = await encryptionService.encrypt(plainText1);
      final encrypted2 = await encryptionService.encrypt(plainText2);

      // Assert
      expect(encrypted1, isNot(equals(encrypted2)));
    });

    test('should encrypt same data to different ciphertext (different IV)', () async {
      // Arrange
      await encryptionService.initialize();
      const plainText = 'same_data';

      // Act
      final encrypted1 = await encryptionService.encrypt(plainText);
      final encrypted2 = await encryptionService.encrypt(plainText);

      // Assert
      expect(encrypted1, isNot(equals(encrypted2))); // Different IVs
    });

    test('should throw SecurityException on invalid encrypted data', () async {
      // Arrange
      await encryptionService.initialize();
      const invalidData = 'invalid_encrypted_data';

      // Act & Assert
      expect(
        () => encryptionService.decrypt(invalidData),
        throwsA(isA<SecurityException>()),
      );
    });

    test('should hash password with salt', () async {
      // Arrange
      const password = 'MySecurePassword123!';

      // Act
      final hashed = await encryptionService.hashPassword(password);

      // Assert
      expect(hashed, isNot(equals(password)));
      expect(hashed.contains(':'), isTrue); // salt:hash format
      final parts = hashed.split(':');
      expect(parts.length, equals(2));
    });

    test('should verify correct password', () async {
      // Arrange
      const password = 'MySecurePassword123!';
      final hashed = await encryptionService.hashPassword(password);

      // Act
      final isValid = await encryptionService.verifyPassword(password, hashed);

      // Assert
      expect(isValid, isTrue);
    });

    test('should reject incorrect password', () async {
      // Arrange
      const password = 'MySecurePassword123!';
      const wrongPassword = 'WrongPassword456!';
      final hashed = await encryptionService.hashPassword(password);

      // Act
      final isValid = await encryptionService.verifyPassword(wrongPassword, hashed);

      // Assert
      expect(isValid, isFalse);
    });

    test('should handle key rotation', () async {
      // Arrange
      await encryptionService.initialize();
      final initialVersion = encryptionService.keyVersion;

      // Act
      await encryptionService.rotateKey();

      // Assert
      expect(encryptionService.keyVersion, greaterThan(initialVersion));
    });

    test('should securely delete keys', () async {
      // Arrange
      await encryptionService.initialize();

      // Act
      await encryptionService.secureDelete();

      // Assert - should be able to reinitialize after deletion
      await encryptionService.initialize();
      expect(encryptionService.keyVersion, isPositive);
    });
  });
}


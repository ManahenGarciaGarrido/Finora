import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/core/security/secure_storage_service.dart';

void main() {
  group('SecureStorageService', () {
    late SecureStorageService secureStorage;

    setUp(() {
      secureStorage = SecureStorageService();
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

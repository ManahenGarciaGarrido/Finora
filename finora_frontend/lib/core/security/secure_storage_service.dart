import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'encryption_service.dart';
import '../errors/exceptions.dart';

/// Service for secure storage of sensitive data
/// Uses flutter_secure_storage with AES-256 encryption
class SecureStorageService {
  final FlutterSecureStorage _secureStorage;
  final EncryptionService _encryptionService;

  SecureStorageService({
    FlutterSecureStorage? secureStorage,
    EncryptionService? encryptionService,
  })  : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            ),
        _encryptionService = encryptionService ?? EncryptionService();

  /// Initialize the service
  Future<void> initialize() async {
    await _encryptionService.initialize();
  }

  /// Write encrypted data to secure storage
  Future<void> write({
    required String key,
    required String value,
    bool encrypt = true,
  }) async {
    try {
      final dataToStore = encrypt
          ? await _encryptionService.encrypt(value)
          : value;

      await _secureStorage.write(key: key, value: dataToStore);
    } catch (e) {
      throw SecurityException(
        message: 'Failed to write secure data: ${e.toString()}',
      );
    }
  }

  /// Read encrypted data from secure storage
  Future<String?> read({
    required String key,
    bool decrypt = true,
  }) async {
    try {
      final storedData = await _secureStorage.read(key: key);

      if (storedData == null) {
        return null;
      }

      return decrypt
          ? await _encryptionService.decrypt(storedData)
          : storedData;
    } catch (e) {
      throw SecurityException(
        message: 'Failed to read secure data: ${e.toString()}',
      );
    }
  }

  /// Delete data from secure storage
  Future<void> delete({required String key}) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      throw SecurityException(
        message: 'Failed to delete secure data: ${e.toString()}',
      );
    }
  }

  /// Check if key exists in secure storage
  Future<bool> containsKey({required String key}) async {
    try {
      return await _secureStorage.containsKey(key: key);
    } catch (e) {
      throw SecurityException(
        message: 'Failed to check key existence: ${e.toString()}',
      );
    }
  }

  /// Read all keys from secure storage
  Future<Map<String, String>> readAll({bool decrypt = true}) async {
    try {
      final allData = await _secureStorage.readAll();

      if (!decrypt) {
        return allData;
      }

      // Decrypt all values
      final decryptedData = <String, String>{};
      for (final entry in allData.entries) {
        try {
          decryptedData[entry.key] =
              await _encryptionService.decrypt(entry.value);
        } catch (e) {
          // If decryption fails, might be non-encrypted data
          decryptedData[entry.key] = entry.value;
        }
      }

      return decryptedData;
    } catch (e) {
      throw SecurityException(
        message: 'Failed to read all secure data: ${e.toString()}',
      );
    }
  }

  /// Delete all data from secure storage
  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw SecurityException(
        message: 'Failed to delete all secure data: ${e.toString()}',
      );
    }
  }

  /// Rotate encryption key and re-encrypt all data
  Future<void> rotateEncryptionKey() async {
    try {
      // Read all current data (decrypted)
      final allData = await readAll(decrypt: true);

      // Rotate the key
      await _encryptionService.rotateKey();

      // Re-encrypt and store all data with new key
      for (final entry in allData.entries) {
        await write(key: entry.key, value: entry.value, encrypt: true);
      }
    } catch (e) {
      throw SecurityException(
        message: 'Key rotation failed: ${e.toString()}',
      );
    }
  }

  /// Securely delete all data (overwrite before deletion)
  Future<void> secureDeleteAll() async {
    try {
      // Overwrite all values with random data before deletion
      final allKeys = (await _secureStorage.readAll()).keys;

      for (final key in allKeys) {
        // Overwrite with random encrypted data
        final randomData = DateTime.now().millisecondsSinceEpoch.toString();
        await write(key: key, value: randomData, encrypt: true);
      }

      // Delete all
      await deleteAll();

      // Delete encryption keys
      await _encryptionService.secureDelete();
    } catch (e) {
      throw SecurityException(
        message: 'Secure deletion failed: ${e.toString()}',
      );
    }
  }

  /// Get encryption key version
  int get keyVersion => _encryptionService.keyVersion;
}

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import '../constants/encryption_config.dart';
import '../errors/exceptions.dart';

/// Service for encrypting and decrypting sensitive data using AES-256
class EncryptionService {
  final FlutterSecureStorage _secureStorage;
  enc.Key? _cachedKey;
  int? _cachedKeyVersion;

  EncryptionService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Initialize encryption key (generate if doesn't exist)
  Future<void> initialize() async {
    try {
      final existingKey = await _secureStorage.read(key: EncryptionConfig.masterKeyId);

      if (existingKey == null) {
        // Generate new master key
        await _generateMasterKey();
      }

      // Load key version
      final versionStr = await _secureStorage.read(key: EncryptionConfig.keyVersionId);
      _cachedKeyVersion = versionStr != null
          ? int.tryParse(versionStr) ?? EncryptionConfig.currentKeyVersion
          : EncryptionConfig.currentKeyVersion;
    } catch (e) {
      throw SecurityException(
        message: 'Failed to initialize encryption: ${e.toString()}',
      );
    }
  }

  /// Generate a new master encryption key
  Future<void> _generateMasterKey() async {
    try {
      // Generate random 256-bit key
      final random = Random.secure();
      final keyBytes = Uint8List(EncryptionConfig.keySizeBytes);
      for (int i = 0; i < keyBytes.length; i++) {
        keyBytes[i] = random.nextInt(256);
      }

      // Convert to base64 for storage
      final keyBase64 = base64Encode(keyBytes);

      // Generate salt
      final salt = _generateSalt();
      final saltBase64 = base64Encode(salt);

      // Store in secure storage
      await _secureStorage.write(
        key: EncryptionConfig.masterKeyId,
        value: keyBase64,
      );
      await _secureStorage.write(
        key: EncryptionConfig.saltId,
        value: saltBase64,
      );
      await _secureStorage.write(
        key: EncryptionConfig.keyVersionId,
        value: EncryptionConfig.currentKeyVersion.toString(),
      );

      _cachedKey = enc.Key(keyBytes);
      _cachedKeyVersion = EncryptionConfig.currentKeyVersion;
    } catch (e) {
      throw SecurityException(
        message: 'Failed to generate master key: ${e.toString()}',
      );
    }
  }

  /// Get the current encryption key
  Future<enc.Key> _getKey() async {
    if (_cachedKey != null) {
      return _cachedKey!;
    }

    try {
      final keyBase64 = await _secureStorage.read(key: EncryptionConfig.masterKeyId);

      if (keyBase64 == null) {
        await _generateMasterKey();
        return _cachedKey!;
      }

      final keyBytes = base64Decode(keyBase64);
      _cachedKey = enc.Key(keyBytes);
      return _cachedKey!;
    } catch (e) {
      throw SecurityException(
        message: 'Failed to get encryption key: ${e.toString()}',
      );
    }
  }

  /// Encrypt data with AES-256-GCM
  Future<String> encrypt(String plainText) async {
    try {
      final key = await _getKey();
      final iv = _generateIV();

      final encrypter = enc.Encrypter(
        enc.AES(key, mode: enc.AESMode.gcm),
      );

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Package: version|iv|encrypted_data
      final package = {
        'v': _cachedKeyVersion ?? EncryptionConfig.currentKeyVersion,
        'iv': iv.base64,
        'data': encrypted.base64,
      };

      return base64Encode(utf8.encode(json.encode(package)));
    } catch (e) {
      throw SecurityException(
        message: 'Encryption failed: ${e.toString()}',
      );
    }
  }

  /// Decrypt data with AES-256-GCM
  Future<String> decrypt(String encryptedData) async {
    try {
      final key = await _getKey();

      // Unpackage: version|iv|encrypted_data
      final packageBytes = base64Decode(encryptedData);
      final packageJson = utf8.decode(packageBytes);
      final package = json.decode(packageJson) as Map<String, dynamic>;

      final version = package['v'] as int;
      final ivBase64 = package['iv'] as String;
      final dataBase64 = package['data'] as String;

      // Check version compatibility
      if (version > EncryptionConfig.currentKeyVersion) {
        throw SecurityException(
          message: 'Encrypted data version $version is not supported',
        );
      }

      final iv = enc.IV.fromBase64(ivBase64);
      final encrypter = enc.Encrypter(
        enc.AES(key, mode: enc.AESMode.gcm),
      );

      final decrypted = encrypter.decrypt64(dataBase64, iv: iv);
      return decrypted;
    } catch (e) {
      if (e is SecurityException) rethrow;
      throw SecurityException(
        message: 'Decryption failed: ${e.toString()}',
      );
    }
  }

  /// Generate a random initialization vector
  enc.IV _generateIV() {
    final random = Random.secure();
    final bytes = Uint8List(EncryptionConfig.ivSize);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return enc.IV(bytes);
  }

  /// Generate a random salt
  Uint8List _generateSalt() {
    final random = Random.secure();
    final bytes = Uint8List(EncryptionConfig.saltSize);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Hash password with SHA-256 and salt (for client-side verification)
  /// Note: Server should use bcrypt or Argon2 for password storage
  Future<String> hashPassword(String password, {String? providedSalt}) async {
    try {
      // Get or generate salt
      String saltBase64;
      if (providedSalt != null) {
        saltBase64 = providedSalt;
      } else {
        final saltBytes = _generateSalt();
        saltBase64 = base64Encode(saltBytes);
      }

      final saltBytes = base64Decode(saltBase64);

      // Combine password and salt
      final passwordBytes = utf8.encode(password);
      final combined = Uint8List.fromList([...passwordBytes, ...saltBytes]);

      // Hash with SHA-256 multiple times (PBKDF2-like)
      var hash = combined;
      for (int i = 0; i < EncryptionConfig.pbkdf2Iterations; i++) {
        hash = Uint8List.fromList(sha256.convert(hash).bytes);
      }

      // Return salt:hash format
      return '$saltBase64:${base64Encode(hash)}';
    } catch (e) {
      throw SecurityException(
        message: 'Password hashing failed: ${e.toString()}',
      );
    }
  }

  /// Verify password hash
  Future<bool> verifyPassword(String password, String hashedPassword) async {
    try {
      final parts = hashedPassword.split(':');
      if (parts.length != 2) {
        return false;
      }

      final salt = parts[0];
      final expectedHash = parts[1];

      final actualHashed = await hashPassword(password, providedSalt: salt);
      final actualHash = actualHashed.split(':')[1];

      return actualHash == expectedHash;
    } catch (e) {
      return false;
    }
  }

  /// Rotate encryption key (re-encrypt all data with new key)
  Future<void> rotateKey() async {
    try {
      // Generate new key
      await _generateMasterKey();

      // Increment version
      final newVersion = (_cachedKeyVersion ?? EncryptionConfig.currentKeyVersion) + 1;
      await _secureStorage.write(
        key: EncryptionConfig.keyVersionId,
        value: newVersion.toString(),
      );
      _cachedKeyVersion = newVersion;

      // Note: After key rotation, all encrypted data needs to be re-encrypted
      // This should be handled by the calling code
    } catch (e) {
      throw SecurityException(
        message: 'Key rotation failed: ${e.toString()}',
      );
    }
  }

  /// Securely delete all encryption keys and data
  Future<void> secureDelete() async {
    try {
      // Overwrite keys with random data before deletion
      final random = Random.secure();
      final randomBytes = Uint8List(EncryptionConfig.keySizeBytes);
      for (int i = 0; i < randomBytes.length; i++) {
        randomBytes[i] = random.nextInt(256);
      }

      // Overwrite multiple times
      for (int i = 0; i < 3; i++) {
        await _secureStorage.write(
          key: EncryptionConfig.masterKeyId,
          value: base64Encode(randomBytes),
        );
      }

      // Delete keys
      await _secureStorage.delete(key: EncryptionConfig.masterKeyId);
      await _secureStorage.delete(key: EncryptionConfig.saltId);
      await _secureStorage.delete(key: EncryptionConfig.keyVersionId);

      // Clear cache
      _cachedKey = null;
      _cachedKeyVersion = null;
    } catch (e) {
      throw SecurityException(
        message: 'Secure deletion failed: ${e.toString()}',
      );
    }
  }

  /// Get current key version
  int get keyVersion => _cachedKeyVersion ?? EncryptionConfig.currentKeyVersion;
}

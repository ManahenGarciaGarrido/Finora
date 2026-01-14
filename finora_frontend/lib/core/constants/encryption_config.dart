/// Encryption configuration constants for secure data storage
class EncryptionConfig {
  // Private constructor to prevent instantiation
  EncryptionConfig._();

  /// Encryption algorithm (AES-256-GCM)
  static const String algorithm = 'AES-256-GCM';

  /// Key size in bits
  static const int keySize = 256;

  /// Key size in bytes (256 bits / 8)
  static const int keySizeBytes = 32;

  /// IV (Initialization Vector) size in bytes
  static const int ivSize = 16;

  /// Salt size for key derivation in bytes
  static const int saltSize = 16;

  /// PBKDF2 iterations for key derivation
  static const int pbkdf2Iterations = 100000;

  /// Master key identifier in secure storage
  static const String masterKeyId = 'master_encryption_key';

  /// Salt identifier in secure storage
  static const String saltId = 'encryption_salt';

  /// Key version for rotation support
  static const String keyVersionId = 'key_version';

  /// Current key version
  static const int currentKeyVersion = 1;

  /// Encrypted data format version
  static const int dataFormatVersion = 1;
}

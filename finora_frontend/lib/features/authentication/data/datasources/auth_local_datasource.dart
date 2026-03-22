import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../models/user_model.dart';

/// Local data source for authentication
/// Handles local storage of authentication data with AES-256 encryption
abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel> getCachedUser();
  Future<void> clearCache();
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
  Future<bool> isLoggedIn();
  Future<void> secureDeleteAll();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _cachedUserKey = 'CACHED_USER';
  final SecureStorageService _secureStorage;

  AuthLocalDataSourceImpl({SecureStorageService? secureStorage})
    : _secureStorage = secureStorage ?? SecureStorageService();

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await _secureStorage.initialize();

      final userJson = json.encode(user.toJson());

      // Store user data encrypted with AES-256
      await _secureStorage.write(
        key: _cachedUserKey,
        value: userJson,
        encrypt: true,
      );

      // Store user ID and email encrypted
      await _secureStorage.write(
        key: StorageKeys.userId,
        value: user.id,
        encrypt: true,
      );
      await _secureStorage.write(
        key: StorageKeys.userEmail,
        value: user.email,
        encrypt: true,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to cache user: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> getCachedUser() async {
    try {
      await _secureStorage.initialize();

      final userJson = await _secureStorage.read(
        key: _cachedUserKey,
        decrypt: true,
      );

      if (userJson == null) {
        throw const CacheException(message: 'No cached user found');
      }

      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(
        message: 'Failed to get cached user: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _secureStorage.delete(key: _cachedUserKey);
      await _secureStorage.delete(key: StorageKeys.userId);
      await _secureStorage.delete(key: StorageKeys.userEmail);
    } catch (e) {
      throw CacheException(message: 'Failed to clear cache: ${e.toString()}');
    }
  }

  @override
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.initialize();

      // Store access token encrypted with AES-256
      await _secureStorage.write(
        key: StorageKeys.accessToken,
        value: token,
        encrypt: true,
      );

      // Also persist for biometric re-login (survives regular logout).
      await _secureStorage.write(
        key: StorageKeys.biometricToken,
        value: token,
        encrypt: true,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to save token: ${e.toString()}');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      await _secureStorage.initialize();

      return await _secureStorage.read(
        key: StorageKeys.accessToken,
        decrypt: true,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to get token: ${e.toString()}');
    }
  }

  @override
  Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: StorageKeys.accessToken);
    } catch (e) {
      throw CacheException(message: 'Failed to clear token: ${e.toString()}');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> secureDeleteAll() async {
    try {
      // Securely delete all authentication data
      await _secureStorage.secureDeleteAll();

      // Also clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw CacheException(
        message: 'Failed to securely delete data: ${e.toString()}',
      );
    }
  }
}

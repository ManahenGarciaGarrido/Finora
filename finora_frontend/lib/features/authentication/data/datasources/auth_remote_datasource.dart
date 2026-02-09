import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import 'auth_local_datasource.dart';

/// Remote data source for authentication
/// Handles all HTTP requests related to authentication
abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    Map<String, bool>? consents,
  });

  Future<void> logout();

  Future<UserModel> getCurrentUser();

  Future<void> refreshToken();

  Future<void> forgotPassword({required String email});

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<String> enable2FA();

  Future<void> verify2FA({required String code});

  Future<void> disable2FA();

  Future<void> resendVerificationEmail({required String email});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  final AuthLocalDataSource? localDataSource;

  AuthRemoteDataSourceImpl({
    required this.apiClient,
    this.localDataSource,
  });

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Store access token in memory and persistent storage
        final accessToken = data['access_token'] as String?;
        if (accessToken != null) {
          apiClient.setToken(accessToken);
          // Save token to secure storage for session persistence
          if (localDataSource != null) {
            await localDataSource!.saveToken(accessToken);
          }
        }

        // Parse user data
        final userData = data['user'] as Map<String, dynamic>;
        return UserModel.fromJson(userData);
      } else {
        throw ServerException(
          message: 'Login failed',
          code: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException ||
          e is NetworkException ||
          e is AuthenticationException) {
        rethrow;
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    Map<String, bool>? consents,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'name': name,
          'termsAccepted': true,
          'privacyAccepted': true,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (consents != null) 'consents': consents,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Store access token in memory and persistent storage
        final accessToken = data['access_token'] as String?;
        if (accessToken != null) {
          apiClient.setToken(accessToken);
          // Save token to secure storage for session persistence
          if (localDataSource != null) {
            await localDataSource!.saveToken(accessToken);
          }
        }

        // Parse user data
        final userData = data['user'] as Map<String, dynamic>;
        return UserModel.fromJson(userData);
      } else {
        throw ServerException(
          message: 'Registration failed',
          code: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException ||
          e is NetworkException ||
          e is ValidationException) {
        rethrow;
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(ApiEndpoints.logout);
      apiClient.clearToken();
    } catch (e) {
      // Clear token even if request fails
      apiClient.clearToken();
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await apiClient.get(ApiEndpoints.userProfile);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return UserModel.fromJson(data);
      } else {
        throw ServerException(
          message: 'Failed to get user data',
          code: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException ||
          e is NetworkException ||
          e is AuthenticationException) {
        rethrow;
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> refreshToken() async {
    try {
      final response = await apiClient.post(ApiEndpoints.refreshToken);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final accessToken = data['access_token'] as String?;
        if (accessToken != null) {
          apiClient.setToken(accessToken);
        }
      } else {
        throw ServerException(
          message: 'Token refresh failed',
          code: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException ||
          e is NetworkException ||
          e is AuthenticationException) {
        rethrow;
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await apiClient.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await apiClient.post(
        ApiEndpoints.resetPassword,
        data: {
          'token': token,
          'new_password': newPassword,
        },
      );
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<String> enable2FA() async {
    try {
      final response = await apiClient.post(ApiEndpoints.enable2FA);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['qr_code'] as String? ?? data['secret'] as String;
      } else {
        throw ServerException(
          message: 'Failed to enable 2FA',
          code: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> verify2FA({required String code}) async {
    try {
      await apiClient.post(
        ApiEndpoints.verify2FA,
        data: {'code': code},
      );
    } catch (e) {
      if (e is ServerException ||
          e is NetworkException ||
          e is ValidationException) {
        rethrow;
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> disable2FA() async {
    try {
      await apiClient.post(ApiEndpoints.disable2FA);
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> resendVerificationEmail({required String email}) async {
    try {
      await apiClient.post(
        ApiEndpoints.resendVerification,
        data: {'email': email},
      );
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: e.toString());
    }
  }
}

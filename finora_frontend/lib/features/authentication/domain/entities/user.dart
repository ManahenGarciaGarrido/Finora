import 'package:equatable/equatable.dart';

/// User entity - Domain layer
/// This is a pure Dart class with no dependencies on external packages
/// (except Equatable for value comparison)
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEmailVerified;
  final bool is2FAEnabled;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    required this.createdAt,
    this.updatedAt,
    this.isEmailVerified = false,
    this.is2FAEnabled = false,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        phoneNumber,
        createdAt,
        updatedAt,
        isEmailVerified,
        is2FAEnabled,
      ];

  /// Copy with method for immutability
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
    bool? is2FAEnabled,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      is2FAEnabled: is2FAEnabled ?? this.is2FAEnabled,
    );
  }
}

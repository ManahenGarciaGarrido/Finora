import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

/// In-memory cache for the current user's profile photo (base64-encoded).
/// Populated once from the API and updated when the user uploads a new photo.
/// All screens that display the user avatar listen to [photoNotifier].
class ProfilePhotoService {
  static final ProfilePhotoService _instance = ProfilePhotoService._();
  factory ProfilePhotoService() => _instance;
  ProfilePhotoService._();

  final ValueNotifier<String?> photoNotifier = ValueNotifier(null);
  bool _fetched = false;

  String? get photo => photoNotifier.value;

  /// Call this from initState of any page that shows the user avatar.
  /// Fetches from the backend only once per app session.
  Future<void> loadIfNeeded(ApiClient client) async {
    if (_fetched) return;
    _fetched = true;
    try {
      final resp = await client.get('/user/profile');
      final data = resp.data as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>? ?? {};
      final photo = user['photoBase64'] as String?;
      if (photo != null && photo.isNotEmpty) {
        photoNotifier.value = photo;
      }
    } catch (_) {}
  }

  /// Call this after a successful photo upload to keep the cache fresh.
  void update(String? base64Photo) {
    photoNotifier.value = base64Photo;
    _fetched = true;
  }

  /// Reset cache on logout so the next user starts fresh.
  void clear() {
    photoNotifier.value = null;
    _fetched = false;
  }
}

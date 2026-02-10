import 'package:supabase_flutter/supabase_flutter.dart';
import 'blog_service.dart';

class UserService {
  final _supabase = Supabase.instance.client;

  Future<void> updateUserProfile({
    required String displayName,
    String? bio,
    String? profilePhotoUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userEmail = user.email;
      if (userEmail == null) {
        throw Exception('User email not found');
      }

      await _supabase
          .from('users')
          .update({
            'email': userEmail,
            'display_name': displayName,
            'bio': bio,
            'profile_photo_url': profilePhotoUrl,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', user.id);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      print('Error getting current user profile: $e');
      return null;
    }
  }

  Future<int> getFollowerCount(String userId) async {
    try {
      final data = await _supabase
          .from('followers')
          .select('id')
          .eq('followed_id', userId);

      return data.length;
    } catch (e) {
      print('Error getting follower count: $e');
      return 0;
    }
  }

  Future<int> getFollowingCount(String userId) async {
    try {
      final data = await _supabase
          .from('followers')
          .select('id')
          .eq('follower_id', userId);

      return data.length;
    } catch (e) {
      print('Error getting following count: $e');
      return 0;
    }
  }

  Future<void> updateProfilePhotoAndRefreshPosts({
    required String userId,
    required String profilePhotoUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await updateUserProfile(
        displayName: user.userMetadata?['display_name'] ?? user.email ?? '',
        profilePhotoUrl: profilePhotoUrl,
      );

      final blogService = BlogService();
      await blogService.refreshUserProfilePhoto(userId, profilePhotoUrl);
    } catch (e) {
      print('Error updating profile photo and refreshing posts: $e');
      rethrow;
    }
  }
}

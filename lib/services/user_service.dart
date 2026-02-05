import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final _supabase = Supabase.instance.client;

  // Update user profile - GETS userId from current authenticated user
  Future<void> updateUserProfile({
    required String displayName,
    String? bio,
    String? profilePhotoUrl,
  }) async {
    try {
      // Get the current authenticated user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the user's email from auth
      final userEmail = user.email;
      if (userEmail == null) {
        throw Exception('User email not found');
      }

      await _supabase
          .from('users')
          .update({
            'email': userEmail, // Make sure email is included
            'display_name': displayName,
            'bio': bio,
            'profile_photo_url': profilePhotoUrl,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', user.id); // Use the authenticated user's ID
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Get user by ID (for getting other users' profiles)
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

  // Get current user's profile
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

  // ============ ADD THESE MISSING METHODS ============

  // Get follower count for a user
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

  // Get following count for a user
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
}

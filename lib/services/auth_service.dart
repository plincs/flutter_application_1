import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? _currentUser;
  Map<String, dynamic>? _userProfile;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Get user profile data - these are from your users table
  String? get displayName => _userProfile?['display_name'] as String?;
  String? get profilePhotoUrl => _userProfile?['profile_photo_url'] as String?;
  String? get bio => _userProfile?['bio'] as String?;
  DateTime? get createdAt => _userProfile?['created_at'] != null
      ? DateTime.parse(_userProfile!['created_at'] as String)
      : null;
  String? get email => _currentUser?.email; // Get email from Supabase User

  // Add notification settings getters
  bool get notificationsEnabled =>
      _userProfile?['notifications_enabled'] as bool? ?? true;
  bool get emailNotifications =>
      _userProfile?['email_notifications'] as bool? ?? true;

  AuthService() {
    _loadCurrentUser();
    _supabase.auth.onAuthStateChange.listen((data) {
      _loadCurrentUser();
    });
  }

  Future<void> _loadCurrentUser() async {
    final user = _supabase.auth.currentUser;

    if (user != null) {
      _currentUser = user;
      await _loadUserProfile(user.id);
    } else {
      _currentUser = null;
      _userProfile = null;
    }

    notifyListeners();
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle(); // Use maybeSingle instead of single to handle null

      if (response != null) {
        _userProfile = response;
      } else {
        _userProfile = null;
      }
    } catch (e) {
      print('Error loading user profile: $e');
      _userProfile = null;
    }
    notifyListeners();
  }

  // Add this method to refresh user data
  Future<void> loadCurrentUser() async {
    await _loadCurrentUser();
  }

  // Sign out method
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _userProfile = null;
    notifyListeners();
  }

  // Sign up method - FIXED with upsert instead of insert
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('🔄 Starting signUp for: $email');

      // First, try to sign up with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      print('Supabase auth response: ${response.user?.id}');

      if (response.user != null) {
        // Create user profile in database
        await _supabase.from('users').upsert({
          'id': response.user!.id,
          'email': email,
          'display_name': displayName,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'id');

        print('✅ User profile created successfully');

        // Force reload of current user
        await _loadCurrentUser();

        // Verify user is loaded
        if (_currentUser == null) {
          throw Exception('User created but not loaded properly');
        }
      } else {
        throw Exception(
          'User registration failed - no user returned from Supabase',
        );
      }
    } catch (e) {
      print('❌ Sign up error details: $e');

      // Clean up: If auth succeeded but profile creation failed, delete the auth user
      try {
        await _supabase.auth.signOut();
      } catch (_) {
        // Ignore sign out errors
      }

      rethrow;
    }
  }

  // Sign in method
  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Reset password method
  Future<void> resetPassword({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Update user profile in AuthService
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? profilePhotoUrl,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user authenticated');
    }

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (profilePhotoUrl != null) updates['profile_photo_url'] = profilePhotoUrl;
    updates['updated_at'] = DateTime.now().toUtc().toIso8601String();

    try {
      await _supabase.from('users').update(updates).eq('id', _currentUser!.id);

      // Refresh user profile
      await _loadUserProfile(_currentUser!.id);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Add method to update notification settings
  Future<void> updateNotificationSettings({
    bool? notificationsEnabled,
    bool? emailNotifications,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user authenticated');
    }

    final updates = <String, dynamic>{};
    if (notificationsEnabled != null) {
      updates['notifications_enabled'] = notificationsEnabled;
    }
    if (emailNotifications != null) {
      updates['email_notifications'] = emailNotifications;
    }
    updates['updated_at'] = DateTime.now().toUtc().toIso8601String();

    try {
      await _supabase.from('users').update(updates).eq('id', _currentUser!.id);

      // Refresh user profile
      await _loadUserProfile(_currentUser!.id);
    } catch (e) {
      print('Error updating notification settings: $e');
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
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }
}

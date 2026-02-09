import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? _currentUser;
  Map<String, dynamic>? _userProfile;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  String? get displayName => _userProfile?['display_name'] as String?;
  String? get profilePhotoUrl => _userProfile?['profile_photo_url'] as String?;
  String? get bio => _userProfile?['bio'] as String?;
  DateTime? get createdAt => _userProfile?['created_at'] != null
      ? DateTime.parse(_userProfile!['created_at'] as String)
      : null;
  String? get email => _currentUser?.email;

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
          .maybeSingle();

      if (response != null) {
        _userProfile = response;
      } else {
        _userProfile = null;
      }
    } catch (e) {
      _userProfile = null;
    }
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    await _loadCurrentUser();
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _userProfile = null;
    notifyListeners();
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      if (response.user != null) {
        await _supabase.from('users').upsert({
          'id': response.user!.id,
          'email': email,
          'display_name': displayName,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'id');

        await _loadCurrentUser();

        if (_currentUser == null) {
          throw Exception('User created but not loaded properly');
        }

        return response;
      } else {
        throw Exception(
          'User registration failed - no user returned from Supabase',
        );
      }
    } catch (e) {
      try {
        await _supabase.auth.signOut();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resetPassword({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

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
      await _loadUserProfile(_currentUser!.id);
    } catch (e) {
      rethrow;
    }
  }

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
      await _loadUserProfile(_currentUser!.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }
}
